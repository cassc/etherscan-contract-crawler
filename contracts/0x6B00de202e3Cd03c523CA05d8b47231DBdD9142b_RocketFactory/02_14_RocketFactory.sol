// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./RocketComponent.sol";
import {Bytes32Utils, UintUtils} from "./Utils.sol";

contract RocketFactory is ERC721, Ownable {
    using UintUtils for uint256;
    using Bytes32Utils for bytes32;
    using StringUtils for string;

    event LaunchPaid(address indexed from, uint256 indexed tokenId);

    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() || adminAddress == _msgSender(),
            "Ownable: caller is not the owner nor the admin"
        );

        _;
    }

    struct Rocket {
        string gpsCoordinates;
        string recoveryStatus;
        string physicalImage;
        string launchVideo;
        uint256 nose;
        uint256 body;
        uint256 tail;
        uint256 assemblyDate;
        uint256 launchDate;
    }

    struct RocketView {
        uint256 tokenId;
        string name;
        string serialNumber;
        string gpsCoordinates;
        string recoveryStatus;
        string physicalImage;
        string launchVideo;
        string rocketType;
        string imageLink;
        uint256 assemblyDate;
        uint256 launchDate;
        uint256 stickers;
        bool payloadEligible;
        RocketComponent.ComponentView nose;
        RocketComponent.ComponentView body;
        RocketComponent.ComponentView tail;
    }

    uint256 private launchPrice;

    uint256 private assemblyStartDate;

    string private baseURI;

    string private ipfsBaseURI;

    string private ipfsRocketFolder;

    address private rocketComponentContract;

    address private adminAddress;

    bytes32[] private rocketNames;

    Rocket[] private rockets;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier tokenExists(uint256 _tokenId) {
        require(
            _exists(_tokenId),
            "ERC721: operator query for nonexistent token"
        );
        _;
    }

    constructor() ERC721("Tom Sachs Rockets", "TSR") {}

    /**
     * @dev Sets the rocket component contract address
     */
    function setRocketComponentContract(address _address)
        external
        onlyOwnerOrAdmin
    {
        rocketComponentContract = _address;
    }

    /**
     * @dev Sets the base URI for IPFS.
     */
    function setIpfsBaseURI(string memory _ipfsBaseURI)
        external
        onlyOwnerOrAdmin
    {
        ipfsBaseURI = _ipfsBaseURI;
    }

    /**
     * @dev Sets the folder containing the rocket images in IPFS
     */
    function setIpfsRocketFolder(string memory _ipfsRocketFolder)
        external
        onlyOwnerOrAdmin
    {
        ipfsRocketFolder = _ipfsRocketFolder;
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwnerOrAdmin {
        baseURI = _uri;
    }

    /**
     * @dev Sets the metadata for a rocket
     */
    function setRocketMetadata(
        uint256 tokenId,
        string memory gpsCoordinates,
        string memory recoveryStatus,
        string memory physicalImage,
        string memory launchVideo,
        uint256 launchDate
    ) external onlyOwnerOrAdmin tokenExists(tokenId) {
        Rocket storage rocket = rockets[tokenId];

        rocket.gpsCoordinates = gpsCoordinates;
        rocket.recoveryStatus = recoveryStatus;
        rocket.physicalImage = physicalImage;
        rocket.launchVideo = launchVideo;
        rocket.launchDate = launchDate;
    }

    /**
     * @dev sets the GPS Coordinates
     */
    function setRocketGPSCoordinates(
        uint256 tokenId,
        string memory gpsCoordinates
    ) external onlyOwnerOrAdmin tokenExists(tokenId) {
        rockets[tokenId].gpsCoordinates = gpsCoordinates;
    }

    /**
     * @dev sets the recovery status
     */
    function setRecoveryStatus(uint256 tokenId, string memory recoveryStatus)
        external
        onlyOwnerOrAdmin
        tokenExists(tokenId)
    {
        rockets[tokenId].recoveryStatus = recoveryStatus;
    }

    /**
     * @dev sets the physical image
     */
    function setPhysicalImage(uint256 tokenId, string memory physicalImage)
        external
        onlyOwnerOrAdmin
        tokenExists(tokenId)
    {
        rockets[tokenId].physicalImage = physicalImage;
    }

    /**
     * @dev sets the launch video
     */
    function setLaunchVideo(uint256 tokenId, string memory launchVideo)
        external
        onlyOwnerOrAdmin
        tokenExists(tokenId)
    {
        rockets[tokenId].launchVideo = launchVideo;
    }

    /**
     * @dev sets the launch date
     */
    function setLaunchDate(uint256 tokenId, uint256 launchDate)
        external
        onlyOwnerOrAdmin
        tokenExists(tokenId)
    {
        rockets[tokenId].launchDate = launchDate;
    }

    /**
     * @dev Sets the price that needs to be payed to launch a rocket
     */
    function setLaunchPrice(uint256 _launchPrice) external onlyOwnerOrAdmin {
        launchPrice = _launchPrice;
    }

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwnerOrAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the admin address for the contract
     */
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin {
        adminAddress = _adminAddress;
    }

    /**
     * @dev Adds names for rockets
     */
    function addNames(bytes32[] memory _rocketNames) external onlyOwnerOrAdmin {
        for (uint256 i; i < _rocketNames.length; i++) {
            rocketNames.push(_rocketNames[i]);
        }
    }

    /**
     * @dev Sets the date when users can start to assembly rockets
     */
    function setAssemblyStartDate(uint256 _assemblyStartDate)
        external
        onlyOwnerOrAdmin
    {
        assemblyStartDate = _assemblyStartDate;
    }

    /**
     * @dev allows admin and owner to mint rockets even before public assembly date starts
     */
    function devMint(
        uint256 noseId,
        uint256 bodyId,
        uint256 tailId
    ) external onlyOwnerOrAdmin {
        assemble(noseId, bodyId, tailId);
    }

    /**
     * @dev mints a new Rocket using the given parts
     */
    function mint(
        uint256 noseId,
        uint256 bodyId,
        uint256 tailId
    ) external payable {
        require(
            assemblyStartDate != 0 && block.timestamp > assemblyStartDate,
            "You are too early"
        );

        assemble(noseId, bodyId, tailId);
    }

    function payForLaunch(uint256 _tokenId) external payable {
        require(
            _exists(_tokenId),
            "ERC721: operator query for nonexistent token"
        );

        require(
            msg.value >= launchPrice,
            "Not enough Ether to pay for the launch"
        );

        emit LaunchPaid(msg.sender, _tokenId);
    }

    /**
     * @dev Returns all the metadata of a given Rocket.
     */
    function retrieve(uint256 _tokenId)
        external
        view
        returns (RocketView memory)
    {
        require(
            _exists(_tokenId),
            "ERC721: operator query for nonexistent token"
        );

        RocketComponent rocketComponent = RocketComponent(
            rocketComponentContract
        );

        Rocket memory rocket = rockets[_tokenId];

        RocketComponent.ComponentView memory nose = rocketComponent.retrieve(
            rockets[_tokenId].nose
        );
        RocketComponent.ComponentView memory body = rocketComponent.retrieve(
            rockets[_tokenId].body
        );
        RocketComponent.ComponentView memory tail = rocketComponent.retrieve(
            rockets[_tokenId].tail
        );

        bool perfectRocket = nose.brand.compareStrings(body.brand) &&
            body.brand.compareStrings(tail.brand);

        uint256 stickers;

        string memory nosePath = nose.brand;
        if (nose.hasSticker) {
            nosePath = string(
                abi.encodePacked(nosePath, "-", nose.sticker, "-sticker")
            );
            stickers++;
        }

        string memory bodyPath = body.brand;
        if (body.hasSticker) {
            bodyPath = string(
                abi.encodePacked(bodyPath, "-", body.sticker, "-sticker")
            );
            stickers++;
        }

        string memory tailPath = tail.brand;
        if (tail.hasSticker) {
            tailPath = string(
                abi.encodePacked(tailPath, "-", tail.sticker, "-sticker")
            );
            stickers++;
        }

        return
            RocketView(
                _tokenId,
                getRocketName(_tokenId),
                buildSerialNumber(_tokenId),
                rocket.gpsCoordinates,
                rocket.recoveryStatus,
                rocket.physicalImage,
                rocket.launchVideo,
                perfectRocket ? "perfect" : "franken",
                string(
                    abi.encodePacked(
                        ipfsBaseURI,
                        ipfsRocketFolder,
                        string(
                            abi.encodePacked(
                                nosePath,
                                "-",
                                bodyPath,
                                "-",
                                tailPath
                            )
                        ).toSlug(),
                        ".png"
                    )
                ),
                rocket.assemblyDate,
                rocket.launchDate,
                stickers,
                _tokenId % 5 == 0, // Every fifth rocket is payload eligible
                nose,
                body,
                tail
            );
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the base URI for IPFS.
     */
    function getIpfsBaseURI() external view returns (string memory) {
        return ipfsBaseURI;
    }

    /**
     * @dev Returns folder name for the rocket images in IPFS.
     */
    function getIpfsRocketFolder() external view returns (string memory) {
        return ipfsRocketFolder;
    }

    /**
     * @dev Returns the total rocket supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return rockets.length;
    }

    /**
     * @dev Returns the launch price
     */
    function getLaunchPrice() external view returns (uint256) {
        return launchPrice;
    }

    // Private and Internal functions

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function buildSerialNumber(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        string memory serialNumber = "2021.192.";
        string memory tokenIdStr = _tokenId.uint2str();

        if (_tokenId >= 100) {
            serialNumber = string(abi.encodePacked(serialNumber, tokenIdStr));
        } else if (_tokenId >= 10) {
            serialNumber = string(
                abi.encodePacked(serialNumber, "0", tokenIdStr)
            );
        } else {
            serialNumber = string(
                abi.encodePacked(serialNumber, "00", tokenIdStr)
            );
        }

        return serialNumber;
    }

    /**
     * @dev returns the name of a rocket for its tokenId
     */
    function getRocketName(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        return rocketNames[tokenId].bytes32ToString();
    }

    function assemble(
        uint256 noseId,
        uint256 bodyId,
        uint256 tailId
    ) private {
        RocketComponent rocketComponent = RocketComponent(
            rocketComponentContract
        );
        rocketComponent.burn(msg.sender, noseId, bodyId, tailId);

        rockets.push(
            Rocket("", "", "", "", noseId, bodyId, tailId, block.timestamp, 0)
        );

        _mint(msg.sender, rockets.length - 1);
    }
}