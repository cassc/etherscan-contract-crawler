// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {StringUtils, UintUtils} from "./Utils.sol";

contract RocketComponent is ERC721, Ownable {
    using UintUtils for uint256;
    using StringUtils for string;

    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() || adminAddress == _msgSender(),
            "Ownable: caller is not the owner nor the admin"
        );

        _;
    }

    struct ComponentModel {
        string brand;
        uint256 from;
        uint256 to;
    }

    struct ComponentView {
        uint256 tokenId;
        string componentType;
        string brand;
        string imageLink;
        bool hasSticker;
        string sticker;
        string serialNumber;
        uint256 edition;
        uint256 total;
    }

    struct ComponentSticker {
        uint256 tokenId;
        uint256 stickerId;
    }

    uint256 private supply;

    uint256 private claimPrice;

    uint256 private earlyAccessStartDate;

    uint256 private claimStartDate;

    uint16 private maxClaimsPerAddress;

    string private baseURI;

    string private ipfsBaseURI;

    address private rocketFactoryContract;

    address private testFlightCrewContract;

    address private adminAddress;

    uint16[] private availableComponents;

    string[] private stickers;

    ComponentModel[] private componentModels;

    mapping(uint256 => bool) private burnedTokens;

    // tokenId -> stickerId
    mapping(uint256 => uint256) private componentStickers;

    mapping(address => uint16) private claimedComponentsPerAddress;

    /**
     * @dev Throws if called by any account other than the Rocket Contract.
     */
    modifier onlyRocketFactory() {
        require(
            msg.sender == rocketFactoryContract,
            "Ownable: caller is not the rocket factory contract"
        );
        _;
    }

    constructor() ERC721("Tom Sachs Rocket Components", "TSRC") {
        // since 0 is the default value for unset in Solidity, create the first sticker as "none"
        // to allow to use the componentStickers map
        stickers.push("none");
    }

    // ONLY OWNER functions

    /**
     * @dev Sets the claim price.
     */
    function setClaimPrice(uint256 _claimPrice) external onlyOwnerOrAdmin {
        claimPrice = _claimPrice;
    }

    /**
     * @dev Allows to withdraw the Ether in the contract.
     */
    function withdraw() external onlyOwnerOrAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the data for the components
     */
    function addComponents(ComponentModel[] memory _components)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < _components.length; i++) {
            componentModels.push(_components[i]);
        }
    }

    /**
     * @dev Adds tokenIds to the list of tokens that can be claimed by
     * users using the claim function.
     */
    function addAvailableComponents(uint16[] memory _availableComponents)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < _availableComponents.length; i++) {
            availableComponents.push(_availableComponents[i]);
        }
    }

    /**
     * @dev Removes a tokenId from the list of tokens that can be claimed by
     * users using the claim function.
     */
    function removeFromAvailableComponents(uint16 tokenId)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < availableComponents.length; i++) {
            if (availableComponents[i] != tokenId) {
                continue;
            }

            availableComponents[i] = availableComponents[
                availableComponents.length - 1
            ];
            availableComponents.pop();

            break;
        }
    }

    /**
     * @dev Removes all tokenIds from the list of tokens that can be claimed by
     * users using the claim function.
     */
    function resetAvailableComponents() external onlyOwnerOrAdmin {
        delete availableComponents;
    }

    /**
     * @dev Returns a list with all the available components that can be claimed by
     * users using the claim function.
     */
    function getAvailableComponents()
        external
        view
        onlyOwnerOrAdmin
        returns (uint16[] memory)
    {
        return availableComponents;
    }

    /**
     * @dev Returns whether or not a tokenId is in the available compoenents list.
     */
    function isInAvailableComponents(uint256 tokenId)
        external
        view
        onlyOwnerOrAdmin
        returns (bool)
    {
        for (uint256 i; i < availableComponents.length; i++) {
            if (availableComponents[i] == tokenId) {
                return true;
            }
        }

        return false;
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
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwnerOrAdmin {
        baseURI = _uri;
    }

    /**
     * @dev Sets the address of the Rocket Factory contract.
     */
    function setRocketFactoryContract(address _address)
        external
        onlyOwnerOrAdmin
    {
        rocketFactoryContract = _address;
    }

    /**
     * @dev Sets the address of the Test Flight Crew Contract.
     */
    function setTestFlightCrewContract(address _address)
        external
        onlyOwnerOrAdmin
    {
        testFlightCrewContract = _address;
    }

    /**
     * @dev Returns the address of the Rocket Factory contract.
     */
    function getRocketFactoryContract()
        external
        view
        onlyOwnerOrAdmin
        returns (address)
    {
        return rocketFactoryContract;
    }

    /**
     * @dev Returns the address of the Test Flight Crew Contract.
     */
    function getTestFlightCrewContract()
        external
        view
        onlyOwnerOrAdmin
        returns (address)
    {
        return testFlightCrewContract;
    }

    /**
     * @dev Onwer only claim function that allows to mint tokens and send them to a given address.
     */
    function ownerClaim(uint256[] memory tokenIds, address to)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < tokenIds.length; i++) {
            mint(to, tokenIds[i]);
        }
    }

    /**
     * @dev Adds new stickers into the contract.
     */
    function addStickers(string[] memory _stickers) external onlyOwnerOrAdmin {
        for (uint256 i; i < _stickers.length; i++) {
            stickers.push(_stickers[i]);
        }
    }

    /**
     * @dev Adds an sticker to a compoenent.
     */
    function addComponentStickers(ComponentSticker[] memory _componentStickers)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < _componentStickers.length; i++) {
            componentStickers[
                _componentStickers[i].tokenId
            ] = _componentStickers[i].stickerId;
        }
    }

    /**
     * @dev Sets the start datetime to allow claims.
     */
    function setClaimStartDate(uint256 _claimStartDate)
        external
        onlyOwnerOrAdmin
    {
        claimStartDate = _claimStartDate;
    }

    /**
     * @dev Sets the start datetime to allow early access claims.
     */
    function setEarlyAccessStartDate(uint256 _earlyAccessStartDate)
        external
        onlyOwnerOrAdmin
    {
        earlyAccessStartDate = _earlyAccessStartDate;
    }

    /**
     * @dev Sets the maximum amount of components that an address can claim
     */
    function setMaxClaimsPerAddress(uint16 _maxClaimsPerAddress)
        external
        onlyOwnerOrAdmin
    {
        maxClaimsPerAddress = _maxClaimsPerAddress;
    }

    /**
     * @dev Sets the admin address for the contract
     */
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin {
        adminAddress = _adminAddress;
    }

    // END ONLY OWNER functions

    // ONLY Rocket Factory functions

    /**
     * @dev Burns rocket components when a rocket is minted. Only can be called by the Rocket Factory contract.
     */
    function burn(
        address _owner,
        uint256 _noseId,
        uint256 _bodyId,
        uint256 _tailId
    ) external onlyRocketFactory {
        require(
            ownerOf(_noseId) == _owner &&
                ownerOf(_bodyId) == _owner &&
                ownerOf(_tailId) == _owner,
            "Invalid owner for given components"
        );

        require(
            _noseId % 3 == 0 && _bodyId % 3 == 1 && _tailId % 3 == 2,
            "Invalid components given"
        );

        _burn(_noseId);
        _burn(_bodyId);
        _burn(_tailId);

        burnedTokens[_noseId] = true;
        burnedTokens[_bodyId] = true;
        burnedTokens[_tailId] = true;

        supply -= 3;
    }

    // END ONLY Rocket Factory functions

    /**
     * @dev Allows to randomly claim an available Component.
     */
    function claim(uint16 amount) external payable {
        require(amount > 0, "At least one component should be claimed");

        require(
            availableComponents.length > 0,
            "No components left to be claimed"
        );

        IERC721 token = IERC721(testFlightCrewContract);
        require(
            (claimStartDate != 0 && claimStartDate <= block.timestamp) ||
                (earlyAccessStartDate <= block.timestamp &&
                    token.balanceOf(msg.sender) > 0),
            "It is not time yet to start claiming"
        );

        require(
            claimedComponentsPerAddress[msg.sender] + amount <=
                maxClaimsPerAddress,
            "You cannot claim more components"
        );

        require(
            msg.sender == tx.origin,
            "Claim can only be called from a wallet"
        );

        if (amount > availableComponents.length) {
            amount = uint16(availableComponents.length);
        }

        uint256 totalClaimPrice = claimPrice * amount;

        require(msg.value >= totalClaimPrice, "Insufficient Ether to claim");

        if (msg.value > totalClaimPrice) {
            payable(msg.sender).transfer(msg.value - totalClaimPrice);
        }

        claimedComponentsPerAddress[msg.sender] += amount;

        for (uint256 i; i < amount; i++) {
            uint256 random = _getRandomNumber(availableComponents.length);
            uint256 tokenId = uint256(availableComponents[random]);

            availableComponents[random] = availableComponents[
                availableComponents.length - 1
            ];
            availableComponents.pop();

            mint(msg.sender, tokenId);
        }
    }

    /**
     * @dev Returns all the metadata of a given Component.
     */
    function retrieve(uint256 _tokenId)
        external
        view
        returns (ComponentView memory)
    {
        for (uint256 i; i < componentModels.length; i++) {
            if (
                _tokenId < componentModels[i].from ||
                _tokenId > componentModels[i].to
            ) {
                continue;
            }

            string memory componentType = _getComponentType(_tokenId);

            (uint256 total, uint256 edition) = _totalComponentEditions(
                _tokenId,
                i
            );

            bool hasSticker;
            string memory stickerName;
            string memory stickerComponentPath;

            if (componentStickers[_tokenId] != 0) {
                hasSticker = true;
                stickerName = stickers[componentStickers[_tokenId]];
                stickerComponentPath = string(
                    abi.encodePacked("-", stickerName, "-sticker")
                );
            }

            string memory serialNumber = "2021.191.";
            string memory tokenIdStr = _tokenId.uint2str();
            if (_tokenId >= 1000) {
                serialNumber = string(
                    abi.encodePacked(serialNumber, tokenIdStr)
                );
            } else if (_tokenId >= 100) {
                serialNumber = string(
                    abi.encodePacked(serialNumber, "0", tokenIdStr)
                );
            } else if (_tokenId >= 10) {
                serialNumber = string(
                    abi.encodePacked(serialNumber, "00", tokenIdStr)
                );
            } else {
                serialNumber = string(
                    abi.encodePacked(serialNumber, "000", tokenIdStr)
                );
            }

            return
                ComponentView(
                    _tokenId,
                    componentType,
                    componentModels[i].brand,
                    string(
                        abi.encodePacked(
                            ipfsBaseURI,
                            componentModels[i].brand.toSlug(),
                            "-",
                            componentType,
                            stickerComponentPath.toSlug(),
                            ".png"
                        )
                    ),
                    hasSticker,
                    stickerName,
                    serialNumber,
                    edition,
                    total
                );
        }

        revert("Component does not exist");
    }

    /**
     * @dev Returns the claim price.
     */
    function getClaimPrice() external view returns (uint256) {
        return claimPrice;
    }

    /**
     * @dev Returns how many components are available to be claimed.
     */
    function getAvailableComponentsCount() external view returns (uint256) {
        return availableComponents.length;
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
     * @dev Returns a list of all the existing stickers.
     */
    function getStickers() external view returns (string[] memory) {
        return stickers;
    }

    /**
     * @dev Returns an sticker by its id.
     */
    function getSticker(uint256 stickerId)
        external
        view
        returns (string memory)
    {
        return stickers[stickerId];
    }

    /**
     * @dev Returns the total rocket supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return supply;
    }

    /**
     * @dev Returns the total amount of claimed components for the given address
     */
    function getClaimedComponentsPerAddress(address _address)
        external
        view
        returns (uint16)
    {
        return claimedComponentsPerAddress[_address];
    }

    // Private and Internal functions

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns if the given Component is a nose, body or tail.
     */
    function _getComponentType(uint256 _tokenId)
        private
        pure
        returns (string memory)
    {
        uint256 modulo = _tokenId % 3;
        if (modulo == 0) {
            return "nose";
        }

        if (modulo == 1) {
            return "body";
        }

        return "tail";
    }

    /**
     * @dev Checks that the token hasn't been burned and that the token exists before minting it.
     * See {ERC721}.
     */
    function mint(address to, uint256 tokenId) private {
        require(burnedTokens[tokenId] == false, "Token was already burned");

        require(
            tokenId <= componentModels[componentModels.length - 1].to,
            "TokenId is out of bounds"
        );

        supply++;

        _mint(to, tokenId);
    }

    /**
     * @dev Returns the edition number and total of editions for a given tokenId.
     */
    function _totalComponentEditions(uint256 tokenId, uint256 modelId)
        private
        view
        returns (uint256, uint256)
    {
        uint256 edition;
        uint256 total;

        for (
            uint256 i = componentModels[modelId].from;
            i <= componentModels[modelId].to;
            i++
        ) {
            if (i % 3 == tokenId % 3) {
                total++;
            }

            if (tokenId == i) {
                edition = total;
            }
        }

        return (total, edition);
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableComponents.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _upper;
    }
}