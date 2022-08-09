// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721A, ERC721A, ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";

import {FisherYatesShuffler} from "../utils/FisherYatesShuffler.sol";

/// @title 8liensMeta
/// @author 8liens (https://twitter.com/8liensNFT)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract $8liensMeta is
    ERC721A("8liens", "8LIENS"),
    ERC721ABurnable,
    Ownable,
    FisherYatesShuffler
{
    error Busy8lien();
    error NotRevealed();
    error AlreadyRevealed();

    /// @notice max supply of 8liens
    uint256 public constant MAX_SUPPLY = 10001;

    /// @notice provenanceHash used to verify that the metadata are not modified before the reveal
    /// @dev once the reveal started, it can not be modified
    bytes32 public provenanceHash =
        0x64b516cc36cfa6bac1bd4699e54b63df7b817337e24fd9c2c49b19e2d48d0e43;

    /// @notice URL of a big JSON containing an array of MAX_SUPPLY 8liens metadata PRE-REVEAL
    // "don't trust, verify"
    // This variable will be set AFTER reveal. It is here to allow anyone to verify that the team don't mess with metadata
    // -> After reveal, you can open the file, paste its content in this website https://emn178.github.io/online-tools/sha256.html
    // and verify that the hash is the same as provenanceHash
    string public provenanceMetadata;

    /// @notice contains the contract that manages the ChainLink VRF for the reveal process
    // How does the reveal work with provenanceMetadata?!
    // 1) vrfHandler does a call to ChainLink VRF to get one random number
    // -> await vrfHandler.startReveal();
    // 2) this random number seeds a Fisher-Yates algorithm to return a new array containing all numbers in [0, MAX_SUPPLY[, shuffled
    // -> randomArray = await 8liens.getFinaleIds()
    // 3) items in provenanceMetadata are then given the corresponding IDs in this array
    // ->
    // for(let i = 0; i < MAX_SUPPLY; i++) {
    //   provenanceMetadata[i].name = `8lien #${randomArray[i]}`;
    //   await fs.writeFile(`${randomArray[i]}.json`, provenanceMetadata[i]);
    // }
    // 4) we upload the json files to arweave/ipfs and we update the baseURI in thirdEye
    // N.B: for the reveal to be "fast", it is possible that the baseURI will be set to a centralize endpoint
    // until all files are uploaded to a decentralized storage (most probably arweave)
    address public vrfHandler;

    /// @notice Manager of metadata
    address public thirdEye;

    /// @notice contract URI
    string public contractURI;

    /////////////////////////////////////////////////////////
    // Modifiers                                           //
    /////////////////////////////////////////////////////////

    constructor(
        string memory contractURI_,
        address thirdEye_,
        address vrfHandler_
    ) {
        contractURI = contractURI_;
        thirdEye = thirdEye_;
        vrfHandler = vrfHandler_;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        // tokenURI is managed in another contract,
        // allowing an easy update if the project evolves
        return ERC721A(thirdEye).tokenURI(tokenId);
    }

    /// @notice how many items have been minted
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /// @notice returns the final 10 001 randomly shuffled IDs used to sort the provenanceMetadata array
    /// @dev this should only be called off-chain. It's a very expensive function.
    /// @return an array of MAX_SUPPLY
    function getFinaleIds() external view returns (uint256[] memory) {
        uint256 seed = IVRFHandler(vrfHandler).seed();
        if (seed == 0) {
            revert NotRevealed();
        }

        return shuffle(seed, MAX_SUPPLY);
    }

    /// @notice Returns the number of tokens minted by `account`.
    /// @param account the account
    /// @return the number of items minted
    function numberMinted(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to update thirdEye
    /// @param newThridEye the new address of the third eye
    function setThirdEye(address newThridEye) external onlyOwner {
        thirdEye = newThridEye;
    }

    /// @notice Allows owner to update contractURI
    /// @param newContractURI the new contract URI
    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    /// @notice Allows owner to update vrfHandler
    /// @param newVRFHandler the new VRFHandler
    function setVRFHandler(address newVRFHandler) external onlyOwner {
        vrfHandler = newVRFHandler;
    }

    /// @notice Allows owner to set provenanceMetadata
    /// @param newProvenanceMetadata the new contract URI
    function setProvenanceMetadata(string calldata newProvenanceMetadata)
        external
        onlyOwner
    {
        provenanceMetadata = newProvenanceMetadata;
    }

    /// @notice Allows owner to set provenanceHash; it can only be set before seed is set
    /// @param newProvenanceHash the new contract URI
    function setProvenanceHash(bytes32 newProvenanceHash) external onlyOwner {
        if (
            IVRFHandler(vrfHandler).seed() != 0 ||
            IVRFHandler(vrfHandler).requestId() != 0
        ) {
            revert AlreadyRevealed();
        }

        provenanceHash = newProvenanceHash;
    }
}

interface IVRFHandler {
    function seed() external view returns (uint256);

    function requestId() external view returns (uint256);
}