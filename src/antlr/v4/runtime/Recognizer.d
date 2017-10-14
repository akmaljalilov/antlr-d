/*
 * [The "BSD license"]
 *  Copyright (c) 2012 Terence Parr
 *  Copyright (c) 2012 Sam Harwell
 *  Copyright (c) 2017 Egbert Voigt
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

module antlr.v4.runtime.Recognizer;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import antlr.v4.runtime.ANTLRErrorListener;
import antlr.v4.runtime.InterfaceRuleContext;
import antlr.v4.runtime.Token;
import antlr.v4.runtime.TokenConstants;
import antlr.v4.runtime.IntStream;
import antlr.v4.runtime.InterfaceRecognizer;
import antlr.v4.runtime.UnsupportedOperationException;
import antlr.v4.runtime.RecognitionException;
import antlr.v4.runtime.TokenFactory;
import antlr.v4.runtime.CommonToken;
import antlr.v4.runtime.ProxyErrorListener;
import antlr.v4.runtime.Vocabulary;
import antlr.v4.runtime.VocabularyImpl;
import antlr.v4.runtime.atn.ATN;
import antlr.v4.runtime.atn.ParseInfo;
import antlr.v4.runtime.atn.ParserATNSimulator;

// Class Template Recognizer
/**
 * TODO add class description
 */
abstract class Recognizer(U, V) : InterfaceRecognizer
{

    public static immutable int EOF = -1;

    public int[string][Vocabulary] tokenTypeMapCache;

    public int[string][string] ruleIndexMapCache;

    public ANTLRErrorListener!(U,V)[] _listeners;

    protected V _interp;

    private int _stateNumber = -1;

    /**
     * @uml
     * Used to print out token names like ID during debugging and
     * error reporting.  The generated parsers implement a method
     * that overrides this to point to their String[] tokenNames.
     *
     *  @deprecated Use {@link #getVocabulary()} instead.
     */
    abstract public string[] getTokenNames();

    abstract public string[] getRuleNames();

    /**
     * @uml
     * Get the vocabulary used by the recognizer.
     *
     *  @return A {@link Vocabulary} instance providing information about the
     *  vocabulary used by the grammar.
     */
    public Vocabulary getVocabulary()
    {
        return VocabularyImpl.fromTokenNames(getTokenNames());
    }

    /**
     * @uml
     * Get a map from token names to token types.
     * <p>Used for XPath and tree pattern compilation.</p>
     */
    public int[string] getTokenTypeMap()
    {
        Vocabulary vocabulary = getVocabulary();
        int[string] result = tokenTypeMapCache[vocabulary];
        if (result is null) {
            int[string] result1;
            result = result1;
            for (int i = 0; i < getATN.maxTokenType; i++) {
                string literalName = vocabulary.getLiteralName(i);
                if (literalName !is null) {
                    result[literalName] = i;
                }

                string symbolicName = vocabulary.getSymbolicName(i);
                if (symbolicName != null) {
                    result[symbolicName] = i;
                }
            }

            result["EOF"] = TokenConstants.EOF;
            result.rehash; // for faster lookups
            tokenTypeMapCache[vocabulary] = result;
        }
        return result;
    }

    /**
     * @uml
     * Get a map from rule names to rule indexes.
     *
     * <p>Used for XPath and tree pattern compilation.
     */
    public int[string] getRuleIndexMap()
    {
        string[] ruleNames = getRuleNames();
        if (!ruleNames) {
            throw new UnsupportedOperationException("The current recognizer does not provide a list of rule names.");
        }
        int[string] result;
        if (to!string(joiner(ruleNames, ",")) in ruleIndexMapCache) {
            result = ruleIndexMapCache[to!string(joiner(ruleNames, ","))];
        }
        else {
            foreach (int i, rn; ruleNames) {
                result[rn] = i;
            }
            ruleIndexMapCache[to!string(joiner(ruleNames, ","))] = result;
        }
        return result;
    }

    public int getTokenType(string tokenName)
    {
        int ttype = getTokenTypeMap()[tokenName];
        if (ttype) return ttype;
        return TokenConstants.INVALID_TYPE;
    }

    /**
     * @uml
     * If this recognizer was generated, it will have a serialized ATN
     * representation of the grammar.
     *
     * <p>For interpreters, we don't know their serialized ATN despite having
     * created the interpreter from it.</p>
     */
    public string getSerializedATN()
    {
        throw new UnsupportedOperationException("there is no serialized ATN");
    }

    /**
     * @uml
     * For debugging and other purposes, might want the grammar name.
     * Have ANTLR generate an implementation for this method.
     */
    abstract public string getGrammarFileName();

    /**
     * @uml
     * Get the {@link ATN} used by the recognizer for prediction.
     *
     *  @return The {@link ATN} used by the recognizer for prediction.
     */
    abstract public ATN getATN();

    /**
     * @uml
     * Get the ATN interpreter used by the recognizer for prediction.
     *
     *  @return The ATN interpreter used by the recognizer for prediction.
     */
    public V getInterpreter()
    {
        return _interp;
    }

    /**
     * @uml
     * If profiling during the parse/lex, this will return DecisionInfo records
     * for each decision in recognizer in a ParseInfo object.
     */
    public ParseInfo getParseInfo()
    {
        return null;
    }

    public void setInterpreter(V interpreter)
    {
        _interp = interpreter;
    }

    /**
     * @uml
     * What is the error header, normally line/character position information?
     */
    public string getErrorHeader(RecognitionException!(U,V) e)
    {
        int line = e.getOffendingToken().getLine();
        int charPositionInLine = e.getOffendingToken().getCharPositionInLine();
        return "line " ~ to!string(line) ~ ":" ~ to!string(charPositionInLine);
    }

    /**
     * @uml
     * How should a token be displayed in an error message? The default
     * is to display just the text, but during development you might
     * want to have a lot of information spit out.  Override in that case
     * to use t.toString() (which, for CommonToken, dumps everything about
     * the token). This is better than forcing you to override a method in
     * your token objects because you don't have to go modify your lexer
     * so that it creates a new Java type.
     *
     *  @deprecated This method is not called by the ANTLR 4 Runtime. Specific
     * implementations of {@link ANTLRErrorStrategy} may provide a similar
     * feature when necessary. For example, see
     * {@link DefaultErrorStrategy#getTokenErrorDisplay}.
     */
    public string getTokenErrorDisplay(Token t)
    {
	if (t is null) return "<no token>";
        string s = t.getText();
        if (s is null) {
            if (t.getType() == TokenConstants.EOF) {
                s = "<EOF>";
            }
            else {
                s = "<" ~ to!string(t.getType) ~ ">";
            }
        }
        s = s.replace("\n","\\n");
        s = s.replace("\r","\\r");
        s = s.replace("\t","\\t");
        return "'" ~ s ~ "'";
    }

    public void addErrorListener(ANTLRErrorListener!(U, V) listener)
    {
	if (listener is null) {
            assert(0, "listener cannot be null.");
        }

       	_listeners ~= listener;
    }

    public void removeErrorListener(ANTLRErrorListener!(U, V) listener)
    {
        foreach (int elementRemoveIndex, el; _listeners) {
            if (listener == el) {
                _listeners.remove(elementRemoveIndex);
                break;
            }
        }
    }

    public void removeErrorListeners()
    {
        _listeners.length = 0;
    }

    public ANTLRErrorListener!(U,V)[] getErrorListeners()
    {
        return _listeners;
    }

    public ANTLRErrorListener!(U, V) getErrorListenerDispatch()
    {
        return new ProxyErrorListener!(U, V)(getErrorListeners());
    }

    /**
     * @uml
     * subclass needs to override these if there are sempreds or actions
     * that the ATN interp needs to execute
     */
    public bool sempred(InterfaceRuleContext localctx, int ruleIndex, int actionIndex)
    {
        return true;
    }

    public bool precpred(InterfaceRuleContext localctx, int precedence)
    {
        return true;
    }

    public void action(InterfaceRuleContext localctx, int ruleIndex, int actionIndex)
    {
    }

    /**
     * @uml
     * @final
     */
    public final int getState()
    {
        return _stateNumber;
    }

    /**
     * @uml
     * @final
     * Indicate that the recognizer has changed internal state that is
     * consistent with the ATN state passed in.  This way we always know
     * where we are in the ATN as the parser goes along. The rule
     * context objects form a stack that lets us see the stack of
     * invoking rules. Combine this and we have complete ATN
     * configuration information.
     */
    public final void setState(int atnState)
    {
        //writeln("setState "+atnState);
        _stateNumber = atnState;
        // if ( traceATNStates ) _ctx.trace(atnState);
    }

    abstract public IntStream getInputStream();

    abstract public void setInputStream(IntStream input);

    abstract public TokenFactory!CommonToken tokenFactory();

    abstract public void tokenFactory(TokenFactory!CommonToken input);

}
