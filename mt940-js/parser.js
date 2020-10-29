import accountId from './tags/account-id.js';
import closingAvailableBalance from './tags/closing-available-balance.js';
import closingBalance from './tags/closing-balance.js';
import forwardAvailableBalance from './tags/forward-available-balance.js';
import informationForAccountOwner from './tags/information-for-account-owner.js';
import openingBalance from './tags/opening-balance.js';
import relatedReferenceNumber from './tags/related-reference-number.js';
import statementNumber from './tags/statement-number.js';
import transactionInfo from './tags/transaction-info.js';
import transactionReferenceNumber from './tags/transaction-reference-number.js';
import { colonSymbolCode, newLineSymbolCode, returnSymbolCode } from './tokens.js';
var tags = [
    transactionReferenceNumber,
    relatedReferenceNumber,
    accountId,
    statementNumber,
    informationForAccountOwner,
    openingBalance,
    closingBalance,
    closingAvailableBalance,
    forwardAvailableBalance,
    transactionInfo
];
var tagsCount = tags.length;
function closeCurrentTag(state, options) {
    if (state.tag && state.tag.close) {
        state.tag.close(state, options);
    }
}
export function read(data, options) {
    var length = data.length;
    var state = {
        pos: 0,
        statementIndex: -1,
        transactionIndex: -1,
        data: data,
        statements: []
    };
    while (state.pos < length) {
        var symbolCode = data[state.pos];
        var skipReading = false;
        // check if it's a tag
        if (symbolCode === colonSymbolCode && (state.pos === 0 || data[state.pos - 1] === newLineSymbolCode)) {
            for (var i = 0; i < tagsCount; i++) {
                var tag = tags[i];
                var newPos = tag.readToken(state);
                if (newPos) {
                    closeCurrentTag(state, options);
                    state.pos = newPos;
                    state.tagContentStart = newPos;
                    state.tagContentEnd = newPos;
                    state.tag = tag;
                    if (state.tag.open) {
                        state.tag.open(state);
                    }
                    break;
                }
            }
        }
        else if (symbolCode === newLineSymbolCode || symbolCode === returnSymbolCode) {
            skipReading = !state.tag || !state.tag.multiline;
        }
        if (!skipReading && state.tag) {
            if (state.tagContentEnd !== undefined) {
                state.tagContentEnd++;
            }
            if (typeof state.tag.readContent === 'function') {
                state.tag.readContent(state, data[state.pos]);
            }
        }
        state.pos++;
    }
    closeCurrentTag(state, options);
    return Promise.resolve(state.statements);
}
