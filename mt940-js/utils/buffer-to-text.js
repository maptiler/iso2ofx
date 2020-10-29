export default function bufferToText(arr, start, end) {
    return String.fromCharCode.apply(String, [].slice.call(arr, start, end));
}
