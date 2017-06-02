/*
 * [The "BSD license"]
 *  Copyright (c) 2013 Terence Parr
 *  Copyright (c) 2013 Sam Harwell
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module antlr.v4.runtime.atn.LexerActionExecutor;

import std.conv;
import antlr.v4.runtime.Lexer;
import antlr.v4.runtime.CharStream;
import antlr.v4.runtime.atn.LexerAction;
import antlr.v4.runtime.misc.MurmurHash;

// Class LexerActionExecutor
/**
 * @uml
 * Represents an executor for a sequence of lexer actions which traversed during
 * the matching operation of a lexer rule (token).
 *
 * <p>The executor tracks position information for position-dependent lexer actions
 * efficiently, ensuring that actions appearing only at the end of the rule do
 * not cause bloating of the {@link DFA} created for the lexer.</p>
 *
 *  @author Sam Harwell
 *  @since 4.2
 */
class LexerActionExecutor
{

    private LexerAction[] lexerActions;

    /**
     * @uml
     * Caches the result of {@link #hashCode} since the hash code is an element
     * of the performance-critical {@link LexerATNConfig#hashCode} operation.
     */
    private int hashCode_;

    /**
     * @uml
     * Constructs an executor for a sequence of {@link LexerAction} actions.
     *  @param lexerActions The lexer actions to execute.
     */
    public this(LexerAction[] lexerActions)
    {
        this.lexerActions = lexerActions;

        int hash = MurmurHash.initialize();
        foreach (LexerAction lexerAction; lexerActions) {
            hash = MurmurHash.update(hash, lexerAction);
        }
        this.hashCode_ = MurmurHash.finish(hash, to!int(lexerActions.length));
    }

    /**
     * @uml
     * Creates a {@link LexerActionExecutor} which executes the actions forthe input {@code lexerActionExecutor} followed by a specified
     *  {@code lexerAction}.
     *
     *  @param lexerActionExecutor The executor for actions already traversed by
     *  the lexer while matching a token within a particular {@link LexerATNConfig}. If this is {@code null}, the method behaves as
     * though it were an empty executor.
     *  @param lexerAction The lexer action to execute after the actions
     *  specified in {@code lexerActionExecutor}.
     *
     *  @return A {@link LexerActionExecutor} for executing the combine actions
     * of {@code lexerActionExecutor} and {@code lexerAction}.
     */
    public static void append(LexerActionExecutor lexerActionExecutor, LexerAction lexerAction)
    {
        if (lexerActionExecutor is null) {
            LexerAction[] a = [lexerAction];
            return new LexerActionExecutor(a);
        }

        LexerAction[] lexerActions = Arrays.copyOf(lexerActionExecutor.lexerActions, lexerActionExecutor.lexerActions.length + 1);
        lexerActions[lexerActions.length - 1] = lexerAction;
        return new LexerActionExecutor(lexerActions);
    }

    /**
     * @uml
     * Creates a {@link LexerActionExecutor} which encodes the current offset
     * for position-dependent lexer actions.
     *
     * <p>Normally, when the executor encounters lexer actions where
     * {@link LexerAction#isPositionDependent} returns {@code true}, it calls
     * {@link IntStream#seek} on the input {@link CharStream} to set the input
     * position to the <em>end</em> of the current token. This behavior provides
     * for efficient DFA representation of lexer actions which appear at the end
     * of a lexer rule, even when the lexer rule matches a variable number of
     * characters.</p>
     *
     * <p>Prior to traversing a match transition in the ATN, the current offset
     * from the token start index is assigned to all position-dependent lexer
     * actions which have not already been assigned a fixed offset. By storing
     * the offsets relative to the token start index, the DFA representation of
     * lexer actions which appear in the middle of tokens remains efficient due
     * to sharing among tokens of the same length, regardless of their absolute
     * position in the input stream.</p>
     *
     * <p>If the current executor already has offsets assigned to all
     * position-dependent lexer actions, the method returns {@code this}.</p>
     *
     *  @param offset The current offset to assign to all position-dependent
     * lexer actions which do not already have offsets assigned.
     *
     *  @return A {@link LexerActionExecutor} which stores input stream offsets
     * for all position-dependent lexer actions.
     */
    public LexerActionExecutor fixOffsetBeforeMatch(int offset)
    {
    }

    public LexerAction[] getLexerActions()
    {
    }

    /**
     * Execute the actions encapsulated by this executor within the context of a
     * particular {@link Lexer}.
     *
     * <p>This method calls {@link IntStream#seek} to set the position of the
     * {@code input} {@link CharStream} prior to calling
     * {@link LexerAction#execute} on a position-dependent action. Before the
     * method returns, the input position will be restored to the same position
     * it was in when the method was invoked.</p>
     *
     * @param lexer The lexer instance.
     * @param input The input stream which is the source for the current token.
     * When this method is called, the current {@link IntStream#index} for
     * {@code input} should be the start of the following token, i.e. 1
     * character past the end of the current token.
     * @param startIndex The token start index. This value may be passed to
     * {@link IntStream#seek} to set the {@code input} position to the beginning
     * of the token.
     */
    public void execute(Lexer lexer, CharStream input, int startIndex)
    {
        bool requiresSeek = false;
        int stopIndex = input.index();
        try {
            foreach (LexerAction lexerAction; lexerActions) {
                if (lexerAction.classinfo == LexerIndexedCustomAction.classinfo) {
                    int offset = (cast(LexerIndexedCustomAction)lexerAction).getOffset();
                    input.seek(startIndex + offset);
                    lexerAction = (cast(LexerIndexedCustomAction)lexerAction).getAction();
                    requiresSeek = (startIndex + offset) != stopIndex;
                }
                else if (lexerAction.isPositionDependent()) {
                    input.seek(stopIndex);
                    requiresSeek = false;
                }

                lexerAction.execute(lexer);
            }
        }
        finally {
            if (requiresSeek) {
                input.seek(stopIndex);
            }
        }

    }

    /**
     * @uml
     * @safe
     * @nothrow
     */
    public int hashCode() @safe nothrow
    {
	return this.hashCode_;
    }

    /**
     * @uml
     * @override
     */
    public override bool opEquals(Object obj)
    {
    }

}
