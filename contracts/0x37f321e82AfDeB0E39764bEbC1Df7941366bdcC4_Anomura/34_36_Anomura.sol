// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IAnomuraData} from "./AnomuraData.sol";

import { IUniversalEquipmentManager } from "./UniversalEquipmentManager.sol";

interface IAnomura {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @notice Anomura contract
/// Allow a bowl owner to hatch an anomura
contract Anomura is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    IAnomuraData public anomuraData;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    string private baseURI;

    /// @dev Emit an event when the contract is deployed
    event ContractDeployed(address owner);

    /// @dev Emit an event so an offchain source can build the metadata URI
    event NewAnomura(
        uint256 indexed crabId,
        string claws,
        string legs,
        string body,
        string shell,
        string background,
        string headpieces
    );

    /// @dev Emit an event when bowl address changed
    event UpdatedBowlContractAddress(address bowlAddress, address sender);

    /// @dev Emit an event when public sale is changed
    event UpdatedPauseContract(bool isPaused, address updatedBy);

    address public bowlAddress;
    bytes32 internal entropyMix;

    struct AnomuraEntity {
        string body;
        string claws;
        string legs;
        string shell;
        string headPieces;
        string background;
    }

    /**
     * @dev Keep track of Anomura from tokenId
     */
    mapping(uint256 => AnomuraEntity) public anomuraMap;

    bool public isPaused;

    IUniversalEquipmentManager public universalEquipmentManager;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    /**
     * @dev Throws if called when contract is paused.
     */
    modifier isNotPaused() {
        require(isPaused == false, "Contract is paused");
        _;
    }

    /// @notice Only bowl contract can call the function
    /// if succeed, use the last address hash to add entropy to next address who calls the function
    modifier onlyBowlContract() {
        require(msg.sender == bowlAddress, "Can only be called by Bowl");
        _;
    }

    modifier isTokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Non existed token");
        _;
    }

    function initialize(
        address _bowlAddress,
        address _anomuraDataAddress,
        string calldata _baseURI
    ) external initializer {
        require(_bowlAddress != address(0x0), "Bowl contract address is 0");
        require(
            _anomuraDataAddress != address(0x0),
            "Anomura Data address is 0"
        );
        __ERC721_init("Anomura", "ANOMURA");
        __ERC721Enumerable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        baseURI = _baseURI;
        bowlAddress = _bowlAddress;
        anomuraData = IAnomuraData(_anomuraDataAddress);
        isPaused = false;

        // to start tokenId at 1, instead of 0.
        _tokenIds.increment();

        // emit event contract is deployed
        emit ContractDeployed(msg.sender);
    }

    /// @notice Generate random uint256
    /// @return Random uint256
    function random(string memory input) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        input,
                        tx.gasprice,
                        msg.sender,
                        block.timestamp,
                        block.basefee,
                        blockhash(block.number - 1),
                        entropyMix
                    )
                )
            );
    }

    /**
    @notice return anomura part as string
    a. We generate a random number, then modulo 94 to get a greatness value.
    b. 
        If greatness > 92, ~1.07% chance then the output would have an unique part.
        If greatness > 83, ~10.64% chance then the output would have prefix, and suffix.
        If greatness > 74, ~20.22% chance then the output would have suffix only.
        If greatness > 65, ~29.79% chance then the output would have prefix only.
        Else the output would only contain the name of the part, a val within the sourceArray
    */
    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray,
        string[] memory prefixes,
        string[] memory suffixes,
        string[] memory unique
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(
                abi.encodePacked(
                    keyPrefix,
                    StringsUpgradeable.toString(tokenId)
                )
            )
        );
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 94;

        if (greatness > 92) {
            output = string(
                abi.encodePacked(unique[rand % unique.length], " ", output)
            );
            return output;
        }

        if (greatness > 83) {
            output = string(
                abi.encodePacked(
                    prefixes[rand % prefixes.length],
                    " ",
                    output,
                    " ",
                    suffixes[rand % suffixes.length]
                )
            );
            return output;
        }

        if (greatness > 74) {
            output = string(
                abi.encodePacked(output, " ", suffixes[rand % suffixes.length])
            );
            return output;
        }

        if (greatness > 65) {
            output = string(
                abi.encodePacked(prefixes[rand % prefixes.length], " ", output)
            );
            return output;
        }
        // does not have any special attributes
        return output;
    }

    /**
    @notice return background part as string output
    a. We generate a random number, then modulo 51 to get a greatness value.
    b. 
        If greatness > 45, ~10% chance then the output would have background prefix.
        Else the output would only contain the name of the part, a val within the sourceArray
    */
    function pluckBackground(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray,
        string[] memory backgroundPrefixes
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(
                abi.encodePacked(
                    keyPrefix,
                    StringsUpgradeable.toString(tokenId)
                )
            )
        );
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 51;

        if (greatness > 45) {
            output = string(
                abi.encodePacked(
                    backgroundPrefixes[rand % backgroundPrefixes.length],
                    " ",
                    output
                )
            );
        }

        return output;
    }

    /**
        @notice return true or false
        Initial hasHeadpiece is false by default.
        4% of having headpiece
    */
    function shouldHaveHeadpieces(uint256 tokenId, string memory keyPrefix)
        internal
        view
        returns (bool hasHeadpiece)
    {
        uint256 rand = random(
            string(
                abi.encodePacked(
                    keyPrefix,
                    StringsUpgradeable.toString(tokenId)
                )
            )
        ) % 101;

        if (rand > 95) {
            hasHeadpiece = true;
        }

        return hasHeadpiece;
    }

    /**
    @notice To set new baseURI for tokenId
    @param _baseURI new baseURI
    */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return
            string(
                abi.encodePacked(baseURI, StringsUpgradeable.toString(tokenId))
            );
    }

    /**
    @notice mint an anomura, only owner can call this function
    @param _address Address of who's going to receive the token
    We generate each part of the anomura, and store in the mapping to be viewed later
    */
    function ownerMintAnomura(address _address)
        external
        isNotPaused
        nonReentrant
        onlyOwner
    {
        require(
            address(anomuraData) != address(0x0),
            "Anomura data address is 0"
        );

        entropyMix = keccak256(abi.encodePacked(_address, block.coinbase));
        uint256 newTokenId = _tokenIds.current();

        IAnomuraData.Data memory data;
        data = anomuraData.getAnomuraData();

        string memory generatedClaws = pluck(
            newTokenId,
            "CLAW",
            data.claws,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedLegs = pluck(
            newTokenId,
            "LEG",
            data.legs,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedBody = pluck(
            newTokenId,
            "BODY",
            data.body,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedShell = pluck(
            newTokenId,
            "SHELL",
            data.shell,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedBackground = pluckBackground(
            newTokenId,
            "BACKGROUND",
            data.background,
            data.backgroundPrefixes
        );

        bool hasHeadpiece = shouldHaveHeadpieces(newTokenId, "HAVE_HEADPIECE");
        string memory generatedHeadPieces = hasHeadpiece == true
            ? pluck(
                newTokenId,
                "HEADPIECE",
                data.headPieces,
                data.prefixes,
                data.suffixes,
                data.unique
            )
            : "None";

        anomuraMap[newTokenId] = AnomuraEntity({
            body: generatedBody,
            claws: generatedClaws,
            legs: generatedLegs,
            shell: generatedShell,
            headPieces: generatedHeadPieces,
            background: generatedBackground
        });

        _tokenIds.increment();
        _safeMint(_address, newTokenId);

        emit NewAnomura(
            newTokenId,
            generatedClaws,
            generatedLegs,
            generatedBody,
            generatedShell,
            generatedBackground,
            generatedHeadPieces
        );
    }

    /**
    @notice mint an anomura, only Bowl Contract can call this function
    @param _address Address of who's going to receive the token
    We generate each part of the anomura, and store in the mapping to be viewed later
    */
    function mintAnomura(address _address)
        external
        isNotPaused
        nonReentrant
        onlyBowlContract
        returns (uint256 anomuraId)
    {
        require(
            address(anomuraData) != address(0x0),
            "Anomura data address is 0"
        );

        entropyMix = keccak256(abi.encodePacked(_address, block.coinbase));
        anomuraId = _tokenIds.current();

        IAnomuraData.Data memory data;
        data = anomuraData.getAnomuraData();

        string memory generatedClaws = pluck(
            anomuraId,
            "CLAW",
            data.claws,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedLegs = pluck(
            anomuraId,
            "LEG",
            data.legs,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedBody = pluck(
            anomuraId,
            "BODY",
            data.body,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedShell = pluck(
            anomuraId,
            "SHELL",
            data.shell,
            data.prefixes,
            data.suffixes,
            data.unique
        );
        string memory generatedBackground = pluckBackground(
            anomuraId,
            "BACKGROUND",
            data.background,
            data.backgroundPrefixes
        );

        bool hasHeadpiece = shouldHaveHeadpieces(anomuraId, "HAVE_HEADPIECE");
        string memory generatedHeadPieces = hasHeadpiece == true
            ? pluck(
                anomuraId,
                "HEADPIECE",
                data.headPieces,
                data.prefixes,
                data.suffixes,
                data.unique
            )
            : "None";

        anomuraMap[anomuraId] = AnomuraEntity({
            body: generatedBody,
            claws: generatedClaws,
            legs: generatedLegs,
            shell: generatedShell,
            headPieces: generatedHeadPieces,
            background: generatedBackground
        });

        _tokenIds.increment();
        _safeMint(_address, anomuraId);

        emit NewAnomura(
            anomuraId,
            generatedClaws,
            generatedLegs,
            generatedBody,
            generatedShell,
            generatedBackground,
            generatedHeadPieces
        );
    }

    function tokensOfOwner(address _ownerAddr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_ownerAddr); // number of token owned by this address
        uint256[] memory tokenIds = new uint256[](tokenCount); // array should be same as number of token owned

        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_ownerAddr, i);
        }

        return tokenIds;
    }

    /**
    @notice withdraw current balance to msg.sender address
    */
    function withdrawAvailableBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
    @notice Manual set the address of the Bowl contract deployed
    @param _bowlAddress Bowl's address deployed
    */
    function setBowlAddress(address _bowlAddress) external onlyOwner {
        // require(address(anomuraContract) == address(0x0), "The anomura address has been set before.");
        // accidentally we may put a wrong address and we cannot revert so comment out the require
        bowlAddress = _bowlAddress;
        emit UpdatedBowlContractAddress(_bowlAddress, msg.sender);
    }

    /**
    @notice Manual set the address of the Anomura Data contract deployed
    @param _anomuraDataAddress Bowl's address deployed
    */
    function setAnomuraData(address _anomuraDataAddress) external onlyOwner {
        anomuraData = IAnomuraData(_anomuraDataAddress);
    }

    /**
    @notice Change status of isPaused, to pause all minting functions
    @param _isPaused boolean to pause
    */
    function setContractPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
        emit UpdatedPauseContract(_isPaused, msg.sender);
    }

    function setUniversalManager(address universalManager_) external onlyOwner {
        universalEquipmentManager = IUniversalEquipmentManager(universalManager_);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {

        uint256 _lastActionOfAnomura = universalEquipmentManager.getLastActionOnNft(address(this), tokenId);
    
        if((_lastActionOfAnomura + 4) > block.number){
            revert("No transfer right after action");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}