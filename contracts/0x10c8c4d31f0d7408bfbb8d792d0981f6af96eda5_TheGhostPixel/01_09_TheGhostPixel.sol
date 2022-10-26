// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./../common/interfaces/ITheDudesFactoryV2.sol";
import "./../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../common/interfaces/ICoreRewarder.sol";

contract TheGhostPixel is Ownable, IERC721Receiver {
    uint256 public constant factoryTokenId = 50;
    uint256 public constant factoryCollectionId = 1;
    uint256 public constant socialExtensionId = 2;
    address public immutable factoryAddress;
    address public immutable extensionStorageAddress;
    address public immutable pixelRewarderAddress;

    bytes32 public constant answerHashed =
        0x9b9e4aebd2f343e8107103759937d585b066d2e1a632557d96a33bcc4c4bb483;

    bool public isMinted;
    bool public isClaimed;

    string tokenMetadataURI;
    string tokenRevealedMetadataURI;

    constructor(
        address _factoryAddress,
        address _extensionStorageAddress,
        address _pixelRewarderAddress,
        string memory _tokenMetadataURI,
        string memory _tokenRevealedMetadataURI
    ) {
        factoryAddress = _factoryAddress;
        extensionStorageAddress = _extensionStorageAddress;
        pixelRewarderAddress = _pixelRewarderAddress;
        tokenMetadataURI = _tokenMetadataURI;
        tokenRevealedMetadataURI = _tokenRevealedMetadataURI;
    }

    function mint() public onlyOwner {
        require(!isMinted, "Already minted");
        isMinted = true;
        ITheDudesFactoryV2(factoryAddress).mint(
            factoryCollectionId,
            address(this),
            0
        );
    }

    function updateTokenMedataURI(string calldata _tokenMetadataURI)
        public
        onlyOwner
    {
        tokenMetadataURI = _tokenMetadataURI;
    }

    function updateTokenRevealedMetadataURI(
        string calldata _tokenRevealedMetadataURI
    ) public onlyOwner {
        tokenRevealedMetadataURI = _tokenRevealedMetadataURI;
    }

    function isAnswerCorrect(string memory answer) public view returns (bool) {
        return answerHashed == keccak256(abi.encodePacked(answer));
    }

    function claim(string memory answer, uint256 pixelTokenId) public {
        require(!isClaimed, "Already claimed");
        require(isAnswerCorrect(answer), "Nope, try a different answer.");

        require(
            ICoreRewarder(pixelRewarderAddress).isOwner(
                msg.sender,
                pixelTokenId
            ),
            "Not authorised - Invalid owner"
        );

        require(
            IThePixelsIncExtensionStorageV2(extensionStorageAddress)
                .currentVariantIdOf(socialExtensionId, pixelTokenId) > 0,
            "This pixel has no social extension"
        );

        isClaimed = true;
        IERC721(factoryAddress).safeTransferFrom(
            address(this),
            msg.sender,
            factoryTokenId
        );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (isClaimed) {
            return tokenRevealedMetadataURI;
        }
        return tokenMetadataURI;
    }

    // ERC721 Receiever

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}