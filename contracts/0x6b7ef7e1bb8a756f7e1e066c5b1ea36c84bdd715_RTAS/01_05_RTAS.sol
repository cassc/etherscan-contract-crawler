// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ORacle-NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    /**                                                                                                                                                                 //
//     *Submitted for verification at Etherscan.io on 2022-08-01                                                                                                          //
//    */                                                                                                                                                                  //
//                                                                                                                                                                        //
//    Todd Anthony Stephens                                                                                                                                               //
//    //   ███    ███                                             ███    ███                                                                                              //
//    // ******************************************@@@/**************&@@@,,,,           @@@@*******************************************************************           //
//    // ..**..*****************/////////**********@@%@@**********@@@*.                     @@@@***********************************..........**.,**************           //
//    // *******************///////////////******@@%%(((@@@@****@@..     @@@@@@@@@@@@@((((      @@************************************************************/           //
//    // *******************////////*************@@%%%%%((((@@((    @#(((/////////////////##@@@@// %@*********************************************************/           //
//    // ********************************[email protected]@[email protected]@##%%%%%@@((    @@(((////////***********,,,,,,##@@@**********************************************************           //
//    // ************************************@@@@**@@%%%@@((    @@(((//////****////*******,,,,,,,,,(#@@********************************************************           //
//    // **************************************@@##@@%@@((((  @@%%%%%##////**///////**********,,,,,,,**##@@****************************************************           //
//    // **************************************@@//((@@@@@@@@@%%%%%%%((////////////*************,,,,,,,,,((@@**************************************************           //
//    // **************************************@@##@@ ....((@@%%%%%%(((((////////*****////********,,,,,,,,,@@@@************************************************           //
//    // **************************************@@,,((@@@  ..((@@%%((@@@@@@@@@@@/////**//****//**///**,,,,,,//@@@@@(********************************************           //
//    // ********.......**..**..***************@@((@@@@@@@  ..##@@((@@@@@@@@@@@@@@@@(/////******///**////////@@[email protected](*******************************........**..*           //
//    // **************************************@@((@@@@@@@  ..##@@((@@@%%%%//////%%@@@@@//////*********//////@@[email protected](********************************************           //
//    // **************************************@@((@@#@@@@  ..##@@(((&@@@&@,,..       ((&&@@/////////////////@@  @(********************************************           //
//    // **************************************@@((@@#%%@@  ..##@@(((((@@@@@@,,..       //&&@@///////////////@@//@(********************************************           //
//    // **************************************@@((@@#%%@@  ..##@@(((((/(@@@@@@,,..       //%%@@(((////((////@@&&@*.....,,,,..,,,,,****************************           //
//    // *******************,,...........,,,,,,@@((@@@@@@@  ..##@@(((((((((((((@@&&&&&&&&&&&@@**************                                                              //
//    // ************************************@@((((*******((####((%%&&&@@//@@###############%%%%%%@@@&&&&##******&&&&&@@***************************************           //
//    // *******************,,**,,,,,,.......,,,,@@%%%%%((((((////%%%&&&&@@@@((&&@@@@@@@@@@@@@@@@@/%&&&&&&&((((///////((@@************************************,           //
//    // ******,,,,,,,,********************,,[email protected]@&&&&@@@@@@@@@******(%%&&&&@@@@  &&&%%%%%%%%%%&&  @&&&&&&&@*******#%&&&&@@**********************,,,,,,,,*******           //
//    // ,,,,,,,,,,************************,,@@&&&&&&&&&&&&&&&@@*****//%%%%&&@@@@  @@@@@@@@@@@  @@&@@&&%%****//(((&@@@@@..,,,,,,,,,,,,,,,,,,,,,,,,,,***********           //
//    // **,,..*********************,,[email protected]@&&&&&&&&&&&&&&&&&&&@@@@@&&////%%&&@@@@&&&[email protected]@@@**@@@@&%%&&**((@@@@@@@@@@@@@*********************,,.,**************           //
//    // **......,,***********,,.........**@@@@&&&&&&&&&&&&&&&&&&&@@@@@@@@@##%%&&@@@@@@@////@@@@@@&&&**((@@@@@@@@@@@@@***********************.....,,***********           //
//    // ,,.......................,,,,,,,**@@@@@@&&%%%%&&&&&&&@@&&@@@@@##@@@@%%%%&&@@@@@  ,,@@@@@@@&&**##%%@@@@@@@&&@@*****************,,,,,,..................           //
//    // ,,,,.................,,,,,,,,,,,,,,,**@@@@%%%%&((%%&&&&@@@@@@@@@&&@@@@@@&&&@@@@  [email protected]@@@@@&&&%%%%@@@@@@@@&&&@@**,,,,,,,,,,,,,,,,,,,,,,,................           //
//    // [email protected]@@@&&&&%&&&&((&&&&@@@@@@@@@&&@@@@@@@@#&&@@@@@@@@@@@@@&&##%%@@@@@@&&&&&@@@@.......................................           //
//    // ********,,....,,,***************,,,,@@@@@@((&&&%%&&&&@@@@@@@@@@@&&&&@@@@[email protected]@@@@@@@@@@@@@@@@&##&&@@@@@@@@&&&@@@@........,,,,,,,,,*********,,....,,,,***           //
//    // ************.......,,*************@@@@&&&&&&#((%%((@@@@@@@@@@@&&&&&&@@@@[email protected]@@@@@@@@@@@@@@@#(@@@@@@@@@@@@@@@@@@@@@,,,,,,,*********************........,           //
//    // ********,,[email protected]@@@@@&&&&&&@@@((&&@@@@@@@@@@@@@@@&&@@@@//&,[email protected]@@@@@@@@@@@@*[email protected]@@@@@@@@@@@@@@@@&&@@,,,,,,,,,***************,,...........           //
//    // .............................,,,@@@@@@@@&&&&&&&%%&&@@@@@@@@@@@@@@@@@@@@@ .&@@@@@@@@@@@@@@@#/@@@@&&@@@@@@@@@&&&&@@@@...................................           //
//    // ....*******************,,,,,,,&&@@&&&&&&&&%%&&&&&@@@@@@@@&&&&&&&&@@@@@&&@@,%@,,@@@@@@@@@@/&@&&@@&&&&@@@@@&&&&&&&&@@&&.................****************           //
//    // ....,,***************,,,,,,,,,@@@@&&&&&&%%@@#%%@@@@@@@@@@&&&&&&&&@@@@@&&@@/&@@@@@@@@@@@@@.%@@@@@&&&&@@@@@@@&&&&&&&&@@.................,***************           //
//    // ........,,,,,,*******,,,,,,,,,@@&&&&&&@@@@@@@@@@@@@@@@@&&&&&&&&&&&@@@@&&@@.&@@@@@@@@@@@@@/&@@@@@&&&&@@@@@@@@@@@@@@@@@@@..................,,,,,,*******           //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    // Identifier: TODD_AO                                                                                                                                              //
//                                                                                                                                                                        //
//    // OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)                                                                                                  //
//                                                                                                                                                                        //
//    pragma solidity ^0.8.0;                                                                                                                                             //
//                                                                                                                                                                        //
//    import "github.com/provable-things/ethereum-api/provableAPI.sol";                                                                                                   //
//                                                                                                                                                                        //
//    import "github.com/provable-things/ethereum-api/contracts/solc-v0.8.x/provableAPI.sol";                                                                             //
//    solc-v0.4.25                                                                                                                                                        //
//    solc-v0.5.x                                                                                                                                                         //
//    solc-v0.6.x                                                                                                                                                         //
//    solc-v0.8.x                                                                                                                                                         //
//    /**                                                                                                                                                                 //
//     * @dev Interface of the ERC165 standard, as defined in the                                                                                                         //
//     * https://eips.ethereum.org/EIPS/eip-165[EIP].                                                                                                                     //
//     *                                                                                                                                                                  //
//     * Implementers can declare support of contract interfaces, which can then be                                                                                       //
//     * queried by others ({ERC165Checker}).                                                                                                                             //
//     *                                                                                                                                                                  //
//     * For an implementation, see {ERC165}.                                                                                                                             //
//     */                                                                                                                                                                 //
//    interface IERC165 {                                                                                                                                                 //
//        /**                                                                                                                                                             //
//         * @dev Returns true if this contract implements the interface defined by                                                                                       //
//         * `interfaceId`. See the corresponding                                                                                                                         //
//         * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]                                                                            //
//         * to learn more about how these ids are created.                                                                                                               //
//         *                                                                                                                                                              //
//         * This function call must use less than 30 000 gas.                                                                                                            //
//         */                                                                                                                                                             //
//        function supportsInterface(bytes4 interfaceId) external view returns (bool);                                                                                    //
//    }                                                                                                                                                                   //
//                                                                                                                                                                        //
//    // OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)                                                                                                   //
//                                                                                                                                                                        //
//    pragma solidity ^0.8.0;                                                                                                                                             //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    /**                                                                                                                                                                 //
//     * @dev Implementation of the {IERC165} interface.                                                                                                                  //
//     *                                                                                                                                                                  //
//     * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check                                              //
//     * for the additional interface id that will be supported. For example:                                                                                             //
//     *                                                                                                                                                                  //
//     * ```solidity                                                                                                                                                      //
//     * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {                                                                     //
//     *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);                                                                 //
//     * }                                                                                                                                                                //
//     * ```                                                                                                                                                              //
//     *                                                                                                                                                                  //
//     * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.                                                                      //
//     */                                                                                                                                                                 //
//    abstract contract ERC165 is IERC165 {                                                                                                                               //
//        /**                                                                                                                                                             //
//         * @dev See {IERC165-supportsInterface}.                                                                                                                        //
//         */                                                                                                                                                             //
//        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {                                                                    //
//            return interfaceId == type(IERC165).interfaceId;                                                                                                            //
//        }                                                                                                                                                               //
//    }                                                                                                                                                                   //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    // OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)                                                                                                                //
//                                                                                                                                                                        //
//    pragma solidity ^0.8.0;                                                                                                                                             //
//                                                                                                                                                                        //
//    /**                                                                                                                                                                 //
//     * @dev String operations.                                                                                                                                          //
//     */                                                                                                                                                                 //
//    library Strings {                                                                                                                                                   //
//        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdefg";                                                                                                    //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Converts a `uint256` to its ASCII `string` decimal representation.                                                                                      //
//         */                                                                                                                                                             //
//        function toString(uint256 value) internal pure returns (string memory) {                                                                                        //
//            // Inspired by OraclizeAPI's implementation - MIT licence                                                                                                   //
//            // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol                                            //
//                                                                                                                                                                        //
//            if (value == 0) {                                                                                                                                           //
//                return "0";                                                                                                                                             //
//            }                                                                                                                                                           //
//            uint256 temp = value;                                                                                                                                       //
//            uint256 digits;                                                                                                                                             //
//            while (temp != 0) {                                                                                                                                         //
//                digits++;                                                                                                                                               //
//                temp /= 10;                                                                                                                                             //
//            }                                                                                                                                                           //
//            bytes memory buffer = new bytes(digits);                                                                                                                    //
//            while (value != 0) {                                                                                                                                        //
//                digits -= 1;                                                                                                                                            //
//                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));                                                                                               //
//                value /= 10;                                                                                                                                            //
//            }                                                                                                                                                           //
//            return string(buffer);                                                                                                                                      //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.                                                                                  //
//         */                                                                                                                                                             //
//        function toHexString(uint256 value) internal pure returns (string memory) {                                                                                     //
//            if (value == 0) {                                                                                                                                           //
//                return "0x00";                                                                                                                                          //
//            }                                                                                                                                                           //
//            uint256 temp = value;                                                                                                                                       //
//            uint256 length = 0;                                                                                                                                         //
//            while (temp != 0) {                                                                                                                                         //
//                length++;                                                                                                                                               //
//                temp >>= 8;                                                                                                                                             //
//            }                                                                                                                                                           //
//            return toHexString(value, length);                                                                                                                          //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.                                                                //
//         */                                                                                                                                                             //
//        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {                                                                     //
//            bytes memory buffer = new bytes(2 * length + 2);                                                                                                            //
//            buffer[0] = "0";                                                                                                                                            //
//            buffer[1] = "x";                                                                                                                                            //
//            for (uint256 i = 2 * length + 1; i > 1; --i) {                                                                                                              //
//                buffer[i] = _HEX_SYMBOLS[value & 0xf];                                                                                                                  //
//                value >>= 4;                                                                                                                                            //
//            }                                                                                                                                                           //
//            require(value == 0, "Strings: hex length insufficient");                                                                                                    //
//            return string(buffer);                                                                                                                                      //
//        }                                                                                                                                                               //
//    }                                                                                                                                                                   //
//                                                                                                                                                                        //
//    // OpenZeppelin Contracts v4.4.1 (utils/Context.sol)                                                                                                                //
//                                                                                                                                                                        //
//    pragma solidity ^0.8.0;                                                                                                                                             //
//                                                                                                                                                                        //
//    /**                                                                                                                                                                 //
//     * @dev Provides information about the current execution context, including the                                                                                     //
//     * sender of the transaction and its data. While these are generally available                                                                                      //
//     * via msg.sender and msg.data, they should not be accessed in such a direct                                                                                        //
//     * manner, since when dealing with meta-transactions the account sending and                                                                                        //
//     * paying for execution may not be the actual sender (as far as an application                                                                                      //
//     * is concerned).                                                                                                                                                   //
//     *                                                                                                                                                                  //
//     * This contract is only required for intermediate, library-like contracts.                                                                                         //
//     */                                                                                                                                                                 //
//    abstract contract Context {                                                                                                                                         //
//        function _msgSender() internal view virtual returns (address) {                                                                                                 //
//            return msg.sender;                                                                                                                                          //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        function _msgData() internal view virtual returns (bytes calldata) {                                                                                            //
//            return msg.data;                                                                                                                                            //
//        }                                                                                                                                                               //
//    }                                                                                                                                                                   //
//                                                                                                                                                                        //
//    // OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)                                                                                                 //
//                                                                                                                                                                        //
//    pragma solidity ^0.8.1;                                                                                                                                             //
//                                                                                                                                                                        //
//    /**                                                                                                                                                                 //
//     * @dev Collection of functions related to the address type                                                                                                         //
//     */                                                                                                                                                                 //
//    library Address {                                                                                                                                                   //
//        /**                                                                                                                                                             //
//         * @dev Returns true if `account` is a contract.                                                                                                                //
//         *                                                                                                                                                              //
//         * [IMPORTANT]                                                                                                                                                  //
//         * ====                                                                                                                                                         //
//         * It is unsafe to assume that an address for which this function returns                                                                                       //
//         * false is an externally-owned account (EOA) and not a contract.                                                                                               //
//         *                                                                                                                                                              //
//         * Among others, `isContract` will return false for the following                                                                                               //
//         * types of addresses:                                                                                                                                          //
//         *                                                                                                                                                              //
//         *  - an externally-owned account                                                                                                                               //
//         *  - a contract in construction                                                                                                                                //
//         *  - an address where a contract will be created                                                                                                               //
//         *  - an address where a contract lived, but was destroyed                                                                                                      //
//         * ====                                                                                                                                                         //
//         *                                                                                                                                                              //
//         * [IMPORTANT]                                                                                                                                                  //
//         * ====                                                                                                                                                         //
//         * You shouldn't rely on `isContract` to protect against flash loan attacks!                                                                                    //
//         *                                                                                                                                                              //
//         * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets                                             //
//         * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract                                                      //
//         * constructor.                                                                                                                                                 //
//         * ====                                                                                                                                                         //
//         */                                                                                                                                                             //
//        function isContract(address account) internal view returns (bool) {                                                                                             //
//            // This method relies on extcodesize/address.code.length, which returns 0                                                                                   //
//            // for contracts in construction, since the code is only stored at the end                                                                                  //
//            // of the constructor execution.                                                                                                                            //
//                                                                                                                                                                        //
//            return account.code.length > 0;                                                                                                                             //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Replacement for Solidity's `transfer`: sends `amount` wei to                                                                                            //
//         * `recipient`, forwarding all available gas and reverting on errors.                                                                                           //
//         *                                                                                                                                                              //
//         * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost                                                                                      //
//         * of certain opcodes, possibly making contracts go over the 2300 gas limit                                                                                     //
//         * imposed by `transfer`, making them unable to receive funds via                                                                                               //
//         * `transfer`. {sendValue} removes this limitation.                                                                                                             //
//         *                                                                                                                                                              //
//         * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].                                                                //
//         *                                                                                                                                                              //
//         * IMPORTANT: because control is transferred to `recipient`, care must be                                                                                       //
//         * taken to not create reentrancy vulnerabilities. Consider using                                                                                               //
//         * {ReentrancyGuard} or the                                                                                                                                     //
//         * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].    //
//         */                                                                                                                                                             //
//        function sendValue(address payable recipient, uint256 amount) internal {                                                                                        //
//            require(address(this).balance >= amount, "Address: insufficient balance");                                                                                  //
//                                                                                                                                                                        //
//            (bool success, ) = recipient.call{value: amount}("");                                                                                                       //
//            require(success, "Address: unable to send value, recipient may have reverted");                                                                             //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Performs a Solidity function call using a low level `call`. A                                                                                           //
//         * plain `call` is an unsafe replacement for a function call: use this                                                                                          //
//         * function instead.                                                                                                                                            //
//         *                                                                                                                                                              //
//         * If `target` reverts with a revert reason, it is bubbled up by this                                                                                           //
//         * function (like regular Solidity function calls).                                                                                                             //
//         *                                                                                                                                                              //
//         * Returns the raw returned data. To convert to the expected return value,                                                                                      //
//         * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].        //
//         *                                                                                                                                                              //
//         * Requirements:                                                                                                                                                //
//         *                                                                                                                                                              //
//         * - `target` must be a contract.                                                                                                                               //
//         * - calling `target` with `data` must not revert.                                                                                                              //
//         *                                                                                                                                                              //
//         * _Available since v3.1._                                                                                                                                      //
//         */                                                                                                                                                             //
//        function functionCall(address target, bytes memory data) internal returns (bytes memory) {                                                                      //
//            return functionCall(target, data, "Address: low-level call failed");                                                                                        //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with                                                                            //
//         * `errorMessage` as a fallback revert reason when `target` reverts.                                                                                            //
//         *                                                                                                                                                              //
//         * _Available since v3.1._                                                                                                                                      //
//         */                                                                                                                                                             //
//        function functionCall(                                                                                                                                          //
//            address target,                                                                                                                                             //
//            bytes memory data,                                                                                                                                          //
//            string memory errorMessage                                                                                                                                  //
//        ) internal returns (bytes memory) {                                                                                                                             //
//            return functionCallWithValue(target, data, 0, errorMessage);                                                                                                //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],                                                                                     //
//         * but also transferring `value` wei to `target`.                                                                                                               //
//         *                                                                                                                                                              //
//         * Requirements:                                                                                                                                                //
//         *                                                                                                                                                              //
//         * - the calling contract must have an ETH balance of at least `value`.                                                                                         //
//         * - the called Solidity function must be `payable`.                                                                                                            //
//         *                                                                                                                                                              //
//         * _Available since v3.1._                                                                                                                                      //
//         */                                                                                                                                                             //
//        function functionCallWithValue(                                                                                                                                 //
//            address target,                                                                                                                                             //
//            bytes memory data,                                                                                                                                          //
//            uint256 value                                                                                                                                               //
//        ) internal returns (bytes memory) {                                                                                                                             //
//            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");                                                             //
//        }                                                                                                                                                               //
//                                                                                                                                                                        //
//        /**                                                                                                                                                             //
//         * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but                                                       //
//         * with `errorMessage` as a fallback revert reason when `target` reverts.                                                                                       //
//         *                                                                                                                                                              //
//         * _Available since v3.1._                                                                                                                                      //
//         */                                                                                                                                                             //
//        function functionCallWithValue(                                                                                                                                 //
//            address target,                                                                                                                                             //
//            bytes memory data,                                                                                                                                          //
//            uint256 value,                                                                                                                                              //
//            string memory errorMessage                                                                                                                                  //
//        ) internal returns (bytes me                                                                                                                                    //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RTAS is ERC721Creator {
    constructor() ERC721Creator("ORacle-NFT", "RTAS") {}
}