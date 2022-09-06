//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

// quu..__
//  $$$b  `---.__
//   "$$b        `--.                          ___.---uuudP
//    `$$b           `.__.------.__     __.---'      $$$$"              .
//      "$b          -'            `-.-'            $$$"              .'|
//        ".                                       d$"             _.'  |
//          `.   /                              ..."             .'     |
//            `./                           ..::-'            _.'       |
//             /                         .:::-'            .-'         .'
//            :                          ::''\          _.'            |
//           .' .-.             .-.           `.      .'               |
//           : /'$$|           [email protected]"$\           `.   .'              _.-'
//          .'|$u$$|          |$$,$$|           |  <            _.-'
//          | `:$$:'          :$$$$$:           `.  `.       .-'
//          :                  `"--'             |    `-.     \
//         :##.       ==             .###.       `.      `.    `\
//         |##:                      :###:        |        >     >
//         |#'     `..'`..'          `###'        x:      /     /
//          \                                   xXX|     /    ./
//           \                                xXXX'|    /   ./
//           /`-.                                  `.  /   /
//          :    `-  ...........,                   | /  .'
//          |         ``:::::::'       .            |<    `.
//          |             ```          |           x| \ `.:``.
//          |                         .'    /'   xXX|  `:`M`M':.
//          |    |                    ;    /:' xXXX'|  -'MMMMM:'
//          `.  .'                   :    /:'       |-'MMMM.-'
//           |  |                   .'   /'        .'MMM.-'
//           `'`'                   :  ,'          |MMM<
//             |                     `'            |tbap\
//              \                                  :MM.-'
//               \                 |              .''
//                \.               `.            /
//                 /     .:::::::.. :           /
//                |     .:::::::::::`.         /
//                |   .:::------------\       /
//               /   .''               >::'  /
//               `',:                 :    .'
//                                    `:.:'
// SudoVerse is an on chain ponzi game played directly from SudoSwap.xyz UI to explore SudoSwap contracts boundaries.
// Full game contract and metadata will be deployed 48 hours after all NFTs are minted from the pool

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/ERC721Enumerable.sol";
import "base64-sol/base64.sol";

interface IRenderer {
    function render(uint256 id) external view returns (string calldata);

    function attributes(uint256 id) external view returns (string calldata);
}

contract SudoVerse is Ownable, ERC721iEnumerable {
    IRenderer public renderer;

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply
    ) ERC721(name, symbol) {
        _maxSupply = maxSupply;
    }

    //can burn keys later if wanted
    function setRenderer(address _contract) external onlyOwner {
        renderer = IRenderer(_contract);
    }

    function _preMint() internal {
        // Update balance for initial owner, defined in ERC721.sol
        _balances[_preMintReceiver] = _maxSupply;

        // Emit the Consecutive Transfer Event
        emit ConsecutiveTransfer(1, _maxSupply, address(0), _preMintReceiver);
    }

    // set _preminter to sudo pool
    function mint(address _to) external onlyOwner {
        _preMintReceiver = _to;
        _preMint();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string
            memory descr = "SudoVerse is an on chain ponzi game played directly from SudoSwap.xyz UI to explore SudoSwap contracts boundaries.";

        string memory image = renderer.render(_tokenId);

        string memory attributes = renderer.attributes(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    (
                        Base64.encode(
                            bytes(
                                (
                                    abi.encodePacked(
                                        '{"name":"SudoVerse #',
                                        uint2str(_tokenId),
                                        '","image": ',
                                        '"',
                                        "data:image/svg+xml;base64,",
                                        Base64.encode(bytes(image)),
                                        '",',
                                        '"description":"',
                                        descr,
                                        '",',
                                        // "}"
                                        attributes
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}