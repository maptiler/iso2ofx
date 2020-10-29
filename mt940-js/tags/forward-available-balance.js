import { colonSymbolCode } from '../tokens.js';
import compareArrays from '../utils/compare-arrays.js';
import openingBalanceTag from './opening-balance.js';
/**
 * @description :65:
 * @type {Uint8Array}
 */
export var token = new Uint8Array([colonSymbolCode, 54, 53, colonSymbolCode]);
var tokenLength = token.length;
var __assign = (this && this.__assign) || Object.assign || function(t) {
    for (var s, i = 1, n = arguments.length; i < n; i++) {
        s = arguments[i];
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
            t[p] = s[p];
    }
    return t;
};
var forwardAvailableBalance = __assign(__assign({}, openingBalanceTag), { readToken: function (state) {
        if (!compareArrays(token, 0, state.data, state.pos, tokenLength)) {
            return 0;
        }
        this.init();
        var statement = state.statements[state.statementIndex];
        if (!statement) {
            return 0;
        }
        statement.forwardAvailableBalance = this.info;
        return state.pos + tokenLength;
    } });
export default forwardAvailableBalance;
