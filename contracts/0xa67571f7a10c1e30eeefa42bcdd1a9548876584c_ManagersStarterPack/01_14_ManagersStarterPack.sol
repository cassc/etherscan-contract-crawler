// SPDX-License-Identifier: MIT
// TBA Contract
// Creator: NFT Guys nftguys.biz

//
//  ________  __    __  ________        __       __
// /        |/  |  /  |/        |      /  \     /  |
// $$$$$$$$/ $$ |  $$ |$$$$$$$$/       $$  \   /$$ |  ______   _______    ______    ______    ______    ______    _______
//    $$ |   $$ |__$$ |$$ |__          $$$  \ /$$$ | /      \ /       \  /      \  /      \  /      \  /      \  /       |
//    $$ |   $$    $$ |$$    |         $$$$  /$$$$ | $$$$$$  |$$$$$$$  | $$$$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$$/
//    $$ |   $$$$$$$$ |$$$$$/          $$ $$ $$/$$ | /    $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$    $$ |$$ |  $$/ $$      \
//    $$ |   $$ |  $$ |$$ |_____       $$ |$$$/ $$ |/$$$$$$$ |$$ |  $$ |/$$$$$$$ |$$ \__$$ |$$$$$$$$/ $$ |       $$$$$$  |
//    $$ |   $$ |  $$ |$$       |      $$ | $/  $$ |$$    $$ |$$ |  $$ |$$    $$ |$$    $$ |$$       |$$ |      /     $$/
//    $$/    $$/   $$/ $$$$$$$$/       $$/      $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$ | $$$$$$$/ $$/       $$$$$$$/
//                                                                                /  \__$$ |
//                                                                                $$    $$/
//                                                                                 $$$$$$/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./interfaces/IERC4906.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";



interface IManagersTBA {
    function balanceOf(address owner) external view returns (uint256);

    function showTBA(uint256 id) external view returns (address);
}

contract ManagersStarterPack is Ownable, ERC1155, ERC1155Supply, ERC2981, IERC4906 {
    // ----------------------------- State variables ------------------------------

    bool public mintLive = true;
    mapping(address => bool) private mintedStatus;
    uint256 nonce = 0;
    string public uriOS;
    IManagersTBA public ManagersTBA;

    // ----------------------------- CONSTRUCTOR ------------------------------

    constructor(address _tba) ERC1155("") {
        _setDefaultRoyalty(0xcF94ba8779848141D685d44452c975C2DdC04945, 500);
        ManagersTBA = IManagersTBA(_tba);
        setURI("https://ipfs.io/ipfs/QmPx8PdrCqyPYHeqVaXJZ8rAX77CaMfkbpZK5ov3xPiZaj/json/");
    }

    ////////////////////////////////////////
    //              SETTERS               //
    ////////////////////////////////////////

    // Fixed values minting for each address, should mint to TBA address Smart Contract
    function mintBatch(uint256 tokenId) public {
        // Find TBA for this TokenId
        address TBA = ManagersTBA.showTBA(tokenId);
        require(mintLive, "Mint is finished");
        require(mintedStatus[TBA] == false, "Already minted");
        require(ManagersTBA.balanceOf(msg.sender) != 0, "You dont own any Managers NFT");

        mintedStatus[TBA] = true;

        uint256[] memory ids = new uint256[](2);
        uint256 random1 = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 5) + 1;
        nonce++;
        uint256 random2 = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 5) + 1;

        // Assign randoms to ids, do the simple way of making the different
        if (random1 == random2) {
            random2 = random2 + 1;
        }
        if (random2 == 6) {
            random2 = 1;
        }

        ids[0] = random1;
        ids[1] = random2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 2;

        _mintBatch(TBA, ids, amounts, "");
    }

    function mintBatchLoop(uint256[] memory tokenIds, uint256 _mintAmount) public {
        uint256 minted = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Check if this one is already minted
            address TBA = ManagersTBA.showTBA(tokenIds[i]);
            if (mintedStatus[TBA] == false && minted < _mintAmount) {
                mintBatch(tokenIds[i]);
                minted++;
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    function setURI(string memory newuri) public onlyOwner {
        _setURI(string(abi.encodePacked(newuri, "{id}.json")));
        uriOS = newuri;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setTokenRoyalty(address royaltieReceiver, uint96 bips) external onlyOwner {
        _setDefaultRoyalty(royaltieReceiver, bips);
    }

    function setMintStatus(bool status) public onlyOwner {
        mintLive = status;
    }

    // Interfaces support
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    ////////////////////////////////////////
    //              GETTERS               //
    ////////////////////////////////////////

    function uri(uint256 _tokenid) public view override returns (string memory) {
        return string(abi.encodePacked(uriOS, _toString(_tokenid), ".json"));
    }
}