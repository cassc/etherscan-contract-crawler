// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

//     ____  __  ______  __________
//    / __ \/ / / / __ \/_  __/ __ \
//   / /_/ / /_/ / / / / / / / / / /
//  / ____/ __  / /_/ / / / / /_/ /
// /_/ __/_/_/_/\____/_/_/__\____/___  _   _______
//    / ____/ __ \/  _/_  __/  _/ __ \/ | / / ___/
//   / __/ / / / // /  / /  / // / / /  |/ /\__ \
//  / /___/ /_/ // /  / / _/ // /_/ / /|  /___/ /
// /_____/_____/___/ /_/ /___/\____/_/ |_//____/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CreatorProvenance.sol";
import "./IDelegationRegistryExcerpt.sol";
import "./URIHandler.sol";
import "./IERC4906.sol";

/// @author shawnprice.eth
/// @title Photo Editions by Shawn Price

//     __________  ______    __________________
//    / ____/ __ \/ ____/   <  <  / ____/ ____/
//   / __/ / /_/ / /  ______/ // /___ \/___ \
//  / /___/ _, _/ /__/_____/ // /___/ /___/ /
// /_____/_/ |_|\____/    /_//_/_____/_____/

contract Edition is
    ERC1155,
    IERC2981,
    IERC4906,
    Ownable,
    URIHandler,
    CreatorProvenance
{
    string public name = "Editions by Shawn Price";
    string public symbol = "SP1";

    uint256 private nextEditionId = 1;
    uint256 public totalSupply = 0;

    string public contractURI;

    address private immutable _DELEGATION_REGISTRY =
        0x00000000000076A84feF008CDAbe6409d2FE638B;
    address private EDITION_CONTRACT;

    mapping(uint256 => uint256) private mintPrices;
    mapping(uint256 => uint256) private mintCloseBlocktimes;
    mapping(uint256 => uint256) private editionSupply;
    mapping(uint256 => bool) private editionIsSealed;

    // EIP-2981 NFT Royalty Standard
    mapping(uint256 => uint256) private royaltyBps;
    mapping(uint256 => address) private royaltyRecipient;

    struct PhotoDetails {
        string name;
        string createdBy;
        string description;
        uint256 imageBytes;
        string imageHash;
        uint256 height;
        string uri;
        uint256 width;
        string aperture;
        uint256 iso;
        string lensModel;
        string shutterSpeed;
        string camera;
        string format;
        string license;
        uint256 createdAt;
    }

    mapping(uint => PhotoDetails) private photos;

    error MintClosed();
    error EditionIsSealed();
    error NotEnoughValueSent();
    error EditionDoesNotExist();
    error TokenCreatorAlreadySet();
    error NotDelegatedOnContract();

    constructor() ERC1155("") {}

    //     ____        __    ___
    //    / __ \__  __/ /_  / (_)____
    //   / /_/ / / / / __ \/ / / ___/
    //  / ____/ /_/ / /_/ / / / /__
    // /_/ ___\__,_/_.___/_/_/\___/_  _
    //    / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function mint(
        address _vault,
        address _recipient,
        uint256 _id,
        uint256 _quantity
    ) external payable {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        if (mintCloseBlocktimes[_id] < block.timestamp) revert MintClosed();
        if (msg.value < (mintPrices[_id] * _quantity)) {
            revert NotEnoughValueSent();
        }

        address recipient = _recipient;

        if (_vault != address(0) && _vault != msg.sender) {
            if (
                !(
                    IDelegationRegistry(_DELEGATION_REGISTRY)
                        .checkDelegateForContract(
                            msg.sender,
                            _vault,
                            EDITION_CONTRACT
                        )
                )
            ) {
                revert NotDelegatedOnContract();
            }
            recipient = _vault;
        }

        _mint(recipient, _id, _quantity, "");

        unchecked {
            editionSupply[_id] += _quantity;
            totalSupply += _quantity;
        }
    }

    //  _    ___
    // | |  / (_)__ _      __
    // | | / / / _ \ | /| / /
    // | |/ / /  __/ |/ |/ /
    // |___/_/\___/|__/|__/       __  _
    //    / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function uri(
        uint256 _id
    ) public view virtual override returns (string memory) {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();

        PhotoDetails memory photo = photos[_id];

        return
            generateURI(
                photo.name,
                photo.createdBy,
                photo.description,
                photo.aperture,
                photo.imageBytes,
                photo.imageHash,
                photo.height,
                photo.uri,
                photo.width,
                photo.iso,
                photo.lensModel,
                photo.shutterSpeed,
                photo.camera,
                photo.format,
                photo.license,
                photo.createdAt
            );
    }

    function royaltyInfo(
        uint256 _id,
        uint256 _value
    ) external view returns (address, uint256) {
        return (royaltyRecipient[_id], (_value * royaltyBps[_id]) / 10000);
    }

    function mintPrice(uint256 _id) external view returns (uint256) {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        return mintPrices[_id];
    }

    function mintCloseBlocktime(uint256 _id) external view returns (uint256) {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        return mintCloseBlocktimes[_id];
    }

    function tokenIsSealed(uint256 _id) external view returns (bool) {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        return editionIsSealed[_id];
    }

    function getEditionSupply(uint256 _id) external view returns (uint256) {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        return editionSupply[_id];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC1155) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface id
            interfaceId == 0xd9b67a26 || // ERC1155 interface id
            interfaceId == 0x0e89341c || // ERC1155 MetadataURI interface id
            interfaceId == 0x49064906 || // ERC4906 Metadata Update interface id
            interfaceId == 0x2a55205a; // ERC2981 Royalties interface id
    }

    //    ____
    //   / __ \_      ______  ___  _____
    //  / / / / | /| / / __ \/ _ \/ ___/
    // / /_/ /| |/ |/ / / / /  __/ /
    // \____/_|__/|__/_/ /_/\___/_/_  _
    //    / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function createEdition(
        uint256 _mintPrice,
        string memory _name,
        string memory _createdBy,
        string memory _description,
        string memory _aperture,
        uint256 _bytes,
        string memory _hash,
        uint256 _height,
        uint256 _iso,
        string memory _lensModel,
        string memory _shutterSpeed,
        string memory _uri,
        uint256 _width,
        string memory _camera,
        string memory _format,
        string memory _license,
        uint256 _createdAt
    ) external onlyOwner {
        mintPrices[nextEditionId] = _mintPrice;

        photos[nextEditionId] = PhotoDetails(
            _name,
            _createdBy,
            _description,
            _bytes,
            _hash,
            _height,
            _uri,
            _width,
            _aperture,
            _iso,
            _lensModel,
            _shutterSpeed,
            _camera,
            _format,
            _license,
            _createdAt
        );

        string memory newUri = generateURI(
            _name,
            _createdBy,
            _description,
            _aperture,
            _bytes,
            _hash,
            _height,
            _uri,
            _width,
            _iso,
            _lensModel,
            _shutterSpeed,
            _camera,
            _format,
            _license,
            _createdAt
        );

        emit URI(newUri, nextEditionId);

        unchecked {
            editionSupply[nextEditionId] = 0;
            ++nextEditionId;
        }
    }

    function setMintPrice(uint256 _id, uint256 _mintPrice) external onlyOwner {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        mintPrices[_id] = _mintPrice;
    }

    function setMintCloseBlocktime(
        uint256 _id,
        uint256 _mintCloseBlocktime
    ) external onlyOwner {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        if (editionIsSealed[_id] == true) revert EditionIsSealed();
        mintCloseBlocktimes[_id] = _mintCloseBlocktime;
    }

    function sealEdition(uint256 _id) external onlyOwner {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        editionIsSealed[_id] = true;
    }

    function setRoyaltyInfo(
        address payable _recipient,
        uint256 _bps,
        uint256 _id
    ) external onlyOwner {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        royaltyRecipient[_id] = _recipient;
        royaltyBps[_id] = _bps;
    }

    function setTokenCreator(
        uint256 _id,
        address _createdBy
    ) external onlyOwner {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        (, bool isCreatorVerified) = provenanceTokenInfo(_id);
        if (isCreatorVerified == true) revert TokenCreatorAlreadySet();

        _setTokenCreator(_id, _createdBy);
    }

    /*
     * @notice
     *
     * This NFT, and nearly all others we know today, will die over
     * the coming decades, centuries, and millennia due to digital decay.
     *
     * This smart contract explores the edges of what a Long NFT could look like.
     *
     * A Long NFT is one that is designed to make it to the end of the final
     * blockchain.
     */
    function setEditionImageURI(
        uint256 _id,
        string memory _uri
    ) external onlyOwner {
        if (_id >= nextEditionId || _id < 1) revert EditionDoesNotExist();
        photos[_id].uri = _uri;
        emit MetadataUpdate(_id);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setContractAddress(address _contractAddress) external onlyOwner {
        EDITION_CONTRACT = _contractAddress;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed");
    }
}