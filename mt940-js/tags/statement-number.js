import { colonSymbolCode, slashSymbolCode } from '../tokens.js';
import bufferToText from '../utils/buffer-to-text.js';
import compareArrays from '../utils/compare-arrays.js';
/**
 * @description :28:
 * @type {Uint8Array}
 */
var token1 = new Uint8Array([colonSymbolCode, 50, 56, colonSymbolCode]);
/**
 * @description :28C:
 * @type {Uint8Array}
 */
var token2 = new Uint8Array([colonSymbolCode, 50, 56, 67, colonSymbolCode]);
var token1Length = token1.length;
var token2Length = token2.length;
var statementNumberTag = {
    readToken: function (state) {
        var isToken1 = compareArrays(token1, 0, state.data, state.pos, token1Length);
        var isToken2 = !isToken1 && compareArrays(token2, 0, state.data, state.pos, token2Length);
        if (!isToken1 && !isToken2) {
            return 0;
        }
        this.slashPos = 0;
        return state.pos + (isToken1 ? token1Length : token2Length);
    },
    readContent: function (state, symbolCode) {
        if (symbolCode === slashSymbolCode) {
            this.slashPos = state.pos;
        }
    },
    close: function (state) {
        var statement = state.statements[state.statementIndex];
        if (!statement) {
            return;
        }
        statement.number = bufferToText(state.data, state.tagContentStart, this.slashPos || state.tagContentEnd);
    }
};
export default statementNumberTag;
