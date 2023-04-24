// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IOKPassTransfer.sol";

contract OrdKittensPass is ERC721A, Ownable, Pausable {
    uint256 public constant OK_BURN_PER = 5;
    uint256 public constant MAX_SUPPLY = 600;

    address public wkAddress = 0xC4771c27FB631FF6046845d06561bF20eF753DaB;
    address public transferAddress = 0xFeB6fd519eB85F952c476c396e8D2FC326fcf1B1;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    bool public transferring;

    string public contractURIString;
    string public tokenImageString =
        "https://northupcrypto.mypinata.cloud/ipfs/QmUvviPmiNysAhjqgLtRwpRZPx81c2ewaHJEFenXkApjjW";
    string public tokenDescription =
        "Ordinal Kitten Passes are a gateway token to obtaining an Ordinal Kitten through burning WarKittens";

    constructor() ERC721A("Ordinal Kittens Pass", "OKP") {
        _pause();
    }

    //////// Public functions
    function mint(uint256[] calldata okIds) external whenNotPaused {
        require(_totalMinted() + 1 <= MAX_SUPPLY, "No more passes available");
        require(okIds.length == OK_BURN_PER, "Burn correct number of kittens");

        // Burn the 5 kittens to get the pass
        for (uint256 i = 0; i < okIds.length; i++) {
            IERC721(wkAddress).transferFrom(msg.sender, burnAddress, okIds[i]);
        }

        _safeMint(msg.sender, 1);
    }

    function burnForOrdinal(uint256 id, string memory ordAddress) external {
        require(transferring, "Not ready for transfer");

        // burn and transfer
        _burn(id, true);
        bool success = IOKPassTransfer(transferAddress).transferOrdinal(
            id,
            msg.sender,
            ordAddress
        );
        require(success, "Transfer must succeed");
    }

    function totalMinted() public view returns (uint256){
        return _totalMinted();
    }

    function contractURI() public view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    contractURIString
                )
            )
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Ordinal Kitten Pass #',
                                Strings.toString(tokenId),
                                '", "description": "',
                                tokenDescription,
                                '", "image": "',
                                tokenImageString,
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    // Cherry-picking from ERC71AQueryable
    function tokensOfOwner(
        address owner
    ) external view virtual returns (uint256[] memory) {
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds;
        assembly {
            tokenIds := mload(0x40)
            mstore(0x40, add(tokenIds, shl(5, add(tokenIdsLength, 1))))
            mstore(tokenIds, tokenIdsLength)
        }
        address currOwnershipAddr;
        uint256 tokenIdsIdx;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ) {
            TokenOwnership memory ownership = _ownershipAt(i);
            assembly {
                // if `ownership.burned == false`.
                if iszero(mload(add(ownership, 0x40))) {
                    if mload(ownership) {
                        currOwnershipAddr := mload(ownership)
                    }
                    if iszero(shl(96, xor(currOwnershipAddr, owner))) {
                        tokenIdsIdx := add(tokenIdsIdx, 1)
                        mstore(add(tokenIds, shl(5, tokenIdsIdx)), i)
                    }
                }
                i := add(i, 1)
            }
        }
        return tokenIds;
    }

    //////// Internal functions

    // Override start token id to set to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //////// Admin functions
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setWKAddress(address _wkAddresss) external onlyOwner {
        wkAddress = _wkAddresss;
    }

    function setTransferAddress(address _transferAddress) external onlyOwner {
        transferAddress = _transferAddress;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    function setTransferring(bool _transferring) external onlyOwner {
        transferring = _transferring;
    }

    function setTokenImageString(
        string memory _tokenImageString
    ) external onlyOwner {
        tokenImageString = _tokenImageString;
    }

    function setTokenDescription(
        string memory _tokenDescription
    ) external onlyOwner {
        tokenDescription = _tokenDescription;
    }

    // Shouldnt need this, just in case
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ, ) = payable(msg.sender).call{value: balance}("");
        require(succ);
    }
}

//[email protected]_ved