// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheFuckUpPill is ERC1155Supply, Ownable {
    using Strings for uint256;

    address public theFuckUpPillsV2;
    string public baseURI;

    uint256 public jointMaxSupply = 2999;
    uint256 public extacyMaxSupply = 1591;
    uint256 public lsdMaxSupply = 499;
    uint256 public poisonMaxSupply = 101;
    uint256 public megaDoseMaxSupply = 10;

    bool public revealed;

    string public hiddenMetadataUri;
    string public uriSuffix = ".json";

    mapping(uint256 => bool) public validPillTypes;

    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validPillTypes[1] = true;
        validPillTypes[2] = true;
        validPillTypes[3] = true;
        validPillTypes[4] = true;
        validPillTypes[5] = true;

        hiddenMetadataUri = "https://thenft.mypinata.cloud/ipfs/QmRZxx1BmhEYd3JkKNHc5snxzY9tN5fwoL7roaxyk94Kcn";

        emit SetBaseURI(baseURI);
    }

    function mintBatch(
        address _userAddress,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        require(ids.length == amounts.length, "length mismatch");
        for (uint256 i; i < ids.length; i++) {
            require(validPillTypes[ids[i]], "invalid pill type");
            if (ids[i] == 1) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= jointMaxSupply,
                    "joint max supply reached"
                );
            }
            if (ids[i] == 2) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= extacyMaxSupply,
                    "ecstasy max supply reached"
                );
            }
            if (ids[i] == 3) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= lsdMaxSupply,
                    "lsd max supply reached"
                );
            }
            if (ids[i] == 4) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= poisonMaxSupply,
                    "poison max supply reached"
                );
            }
            if (ids[i] == 5) {
                require(
                    totalSupply(ids[i]) + amounts[i] <= megaDoseMaxSupply,
                    "megaDose max supply reached"
                );
            }
        }
        _mintBatch(_userAddress, ids, amounts, "");
    }

    function setTheFuckUpV2ContractAddress(address fuckupv2ContractAddress)
        external
        onlyOwner
    {
        theFuckUpPillsV2 = fuckupv2ContractAddress;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function airdropPills(
        address[] memory _to,
        uint256[] memory _tokenType,
        uint256[] memory _amount
    ) external {
        require(
            _to.length == _tokenType.length,
            "wallets and tokenIds length not match"
        );
        require(
            _tokenType.length == _amount.length,
            "tokenIds and amounts length not match"
        );
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            require(validPillTypes[_tokenType[i]], "invalid pill type");
            safeTransferFrom(
                _msgSender(),
                _to[i],
                _tokenType[i],
                _amount[i],
                ""
            );
        }
    }

    function burnPillForAddress(
        uint256 tokenId,
        uint256 _amount,
        address burnTokenAddress
    ) external {
        require(validPillTypes[tokenId], "invalid pill type");
        require(theFuckUpPillsV2 != address(0), "the fuckupv2 address not set");
        require(_msgSender() == theFuckUpPillsV2, "Invalid burner address");
        _burn(burnTokenAddress, tokenId, _amount);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            validPillTypes[_tokenId],
            "URI requested for invalid pill type"
        );

        if (!revealed) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }
}