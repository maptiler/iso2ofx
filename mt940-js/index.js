import md5 from './utils/md5.js';
import * as parser from './parser.js';
var invalidInputMessage = 'invalid input';
export function read(input, options) {
    var data;
    if (typeof Buffer !== 'undefined' && input instanceof Buffer) {
        data = input;
    }
    else if (typeof ArrayBuffer !== 'undefined' && input instanceof ArrayBuffer) {
        data = new Uint8Array(input);
    }
    else {
        return Promise.reject(new Error(invalidInputMessage));
    }
    return parser
        .read(data, Object.assign({
        getTransactionId: function (transaction) {
            return md5(JSON.stringify(transaction));
        }
    }, options))
        .catch(function () {
        return Promise.reject(new Error(invalidInputMessage));
    });
}
