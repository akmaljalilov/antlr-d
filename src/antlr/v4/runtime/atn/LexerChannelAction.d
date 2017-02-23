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

module antlr.v4.runtime.atn.LexerChannelAction;

import std.format;
import std.traits;
import std.conv;
import antlr.v4.runtime.Lexer;
import antlr.v4.runtime.atn.LexerAction;
import antlr.v4.runtime.atn.LexerActionType;
import antlr.v4.runtime.misc.MurmurHash;

// Class LexerChannelAction
/**
 * @uml
 * @final
 */
class LexerChannelAction : LexerAction
{

    private int channel;

    /**
     * @uml
     * Constructs a new {@code channel} action with the specified channel value.
     *  @param channel The channel value to pass to {@link Lexer#setChannel}.
     */
    public this(int channel)
    {
        this.channel = channel;
    }

    /**
     * @uml
     * Gets the channel to use for the {@link Token} created by the lexer
     *  @return The channel to use for the {@link Token} created by the lexer.
     */
    public int getChannel()
    {
        return channel;
    }

    /**
     * @uml
     * @override
     */
    public override LexerActionType getActionType()
    {
        return LexerActionType.CHANNEL;
    }

    /**
     * @uml
     * @override
     */
    public override bool isPositionDependent()
    {
        return false;
    }

    /**
     * @uml
     * <p>This action is implemented by calling {@link Lexer#setChannel} with the
     * value provided by {@link #getChannel}.</p>
     * @override
     */
    public override void execute(Lexer lexer)
    {
        lexer.setChannel(channel);
    }

    public int hashCode()
    {
        int rank(E)(E e) if (is(E == enum))
            {
                foreach (i, member; EnumMembers!E)
                    {
                        if (e == member)
                            return to!int(i);
                    }
                assert(0, "Not an enum member");
            }
        int hash = MurmurHash.initialize();
        hash = MurmurHash.update(hash, rank(getActionType));
        hash = MurmurHash.update(hash, channel);
        return MurmurHash.finish(hash, 2);
    }

    public bool equals(Object obj)
    {
        if (obj is this) {
            return true;
        }
        else if (obj.classinfo != LexerChannelAction.classinfo) {
            return false;
        }
        return channel == (cast(LexerChannelAction)obj).channel;
    }

    /**
     * @uml
     * @override
     */
    public override string toString()
    {
        return format("channel(%d)", channel);
    }

}