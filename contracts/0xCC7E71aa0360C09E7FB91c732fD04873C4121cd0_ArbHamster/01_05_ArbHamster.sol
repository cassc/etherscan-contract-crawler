// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract ArbHamster is ERC721A, Ownable {
    uint256 public maxSupply = 3333;
    uint256 public perWallet = 3;
    uint256 public price = 0.005 ether;
    mapping(uint256 => bool) public isBull;
    mapping(address => uint256) public bullCount;
    mapping(address => bool) public isBurned;
    uint256[] public bullIds;
    uint256[] public bearIds;
    string private bullUri;
    string private bearUri;
    bool public winResult;
    bool public isBullWin;
    bool public sale;

    constructor(string memory _bullUri, string memory _bearUri)
        ERC721A("ArbiHamsters", "ARBHAM")
    {
        bullUri = _bullUri;
        bearUri = _bearUri;
        _safeMint(msg.sender, 45);
    }

    modifier validateTx(uint256 count) {
        require(sale, "Minting hasn't started yet.");
        require(
            _numberMinted(msg.sender) + count <= perWallet,
            "Out of limits"
        );
        require(_totalMinted() + count <= maxSupply, "Out of limits");
        require(msg.value == price * count, "Wrong price.");
        _;
    }

    function mintBull(uint256 count) public payable validateTx(count) {
        for (uint256 i = _totalMinted() + 1; i <= _totalMinted() + count; i++) {
            bullIds.push(i);
            isBull[i] = true;
        }
        _safeMint(msg.sender, count);
    }

    function mintBear(uint256 count) public payable validateTx(count) {
        for (uint256 i = _totalMinted() + 1; i <= _totalMinted() + count; i++) {
            bearIds.push(i);
        }
        _safeMint(msg.sender, count);
    }

    function burnNotWinNft() public {
        uint256 balance = balanceOf(msg.sender);
        require(winResult, "No results yet.");
        require(balance > 0, "You don't own the nft.");
        uint256 canBurn = 0;
        if (isBullWin) {
            canBurn = bullCount[msg.sender];
        } else {
            if (balance >= bullCount[msg.sender]) {
                canBurn = balance - bullCount[msg.sender];
            } else {
                canBurn = bullCount[msg.sender] - balance;
            }
        }
        require(canBurn > 0, "You didn't win.");
        require(!isBurned[msg.sender], "You have already burned the nft.");
        for (uint256 i = 0; i < canBurn; i++) {
            if (!isBullWin) {
                if (bullIds.length > 0) {
                    uint256 last_id = bullIds[bullIds.length - 1];
                    _burn(last_id);
                    isBurned[msg.sender] = true;
                    bullIds.pop();
                }
            } else {
                if (bearIds.length > 0) {
                    uint256 last_id = bearIds[bearIds.length - 1];
                    _burn(last_id);
                    isBurned[msg.sender] = true;
                    bearIds.pop();
                }
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0)) {
            if (isBull[startTokenId]) {
                bullCount[to] += quantity;
            }
        } else {
            if (isBull[startTokenId]) {
                bullCount[to]++;
                if (bullCount[from] - 1 >= 0) {
                    bullCount[from]--;
                }
            }
        }
    }

    function flipSaleStart() public onlyOwner {
        sale = !sale;
    }

    function setWin(bool bullWin) public onlyOwner {
        winResult = true;
        isBullWin = bullWin;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory uri = isBull[tokenId] ? bullUri : bearUri;
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "ArbiHamster #",
                                _toString(tokenId),
                                "",
                                '", "description":"3333 animated hamsters chasing an Arbitrum drop on an AI-generated charts.", "image":"',
                                uri,
                                _toString(tokenId),
                                ".gif",
                                '","attributes":[{"trait_type":"Type", "value":"',isBull[tokenId] ? 'Bull' : 'Bear','"}]','}'
                            )
                        )
                    )
                )
            );
    }
}