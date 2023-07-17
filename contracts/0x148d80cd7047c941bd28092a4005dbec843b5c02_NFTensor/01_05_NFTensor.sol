// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { LibString } from "solmate/utils/LibString.sol";

/// @title NFTensor
/// @author 0xcacti
/// @notice Below is the contract for handling saving queries from which to create NFTs using the response from the
/// Bittensor network
contract NFTensor is ERC721, Owned {
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The owner address.
    address constant OWNER_ADDRESS = 0x89E34F1B212c7412AcaA85f0338a0aD5a89502fE;

    /// @notice wTAO address.
    address constant WTAO_ADDRESS = 0x77E06c9eCCf2E797fd462A92B6D7642EF85b0A44;

    /// @notice The minimum amount of wTAO required to mint an NFT.
    uint256 constant MINT_PRICE = 1e9;

    /// @notice The maximum supply of NFTs that can be minted.
    uint256 constant MAX_SUPPLY = 500;

    /// @notice The length of time during which minting is possible.
    uint256 constant MINT_LENGTH = 10 days;

    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    error MintingPeriodOver();

    error AllNFTsMinted();

    error RejectEmptyString();

    /*//////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Blocktimestamp during construction that signals start of minting period._tokenID
    uint256 immutable MINT_START;

    /// @notice The tokenID of the last token to be minted.
    uint256 public tokenID;

    /// @notice The baseURI for the contract.
    string public baseURI;

    /// @notice The mapping of tokenID to query.
    mapping(uint256 => string) public queries;

    /*//////////////////////////////////////////////////////////////
                               constructor
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("NFTensor", "NFTENSOR") Owned(OWNER_ADDRESS) {
        MINT_START = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                               MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints a token to the sender.
    /// @dev Only callable during the minting period. User must approve the contract to spend their wTAO.
    /// @param query The query to save for the token.
    function mint(string calldata query) external {
        if (isMintingPeriodOver()) {
            revert MintingPeriodOver();
        }

        if (tokenID + 1 > MAX_SUPPLY) {
            revert AllNFTsMinted();
        }

        if (bytes(query).length == 0) {
            revert RejectEmptyString();
        }

        // make sure you are handling this correctly
        require(ERC20(WTAO_ADDRESS).transferFrom(msg.sender, address(this), MINT_PRICE));

        tokenID++;
        queries[tokenID] = query;

        _safeMint(msg.sender, tokenID);
    }

    function isMintingPeriodOver() public view returns (bool) {
        return block.timestamp > MINT_START + MINT_LENGTH;
    }

    /*//////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    /// @notice get the baseURI for the contract
    /// @dev return empty string if the baseURI is not previously set
    /// @param _tokenID the tokenID for which to retrieve metadata
    /// @return the tokenURI for the contract
    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenID.toString())) : "";
    }

    /// @notice set the baseURI for the contract
    /// @dev only callable by owner
    /// @param _baseURI the baseURI to set
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /*//////////////////////////////////////////////////////////////
                               ADMIN
    //////////////////////////////////////////////////////////////*/

    function withdrawWTAO() external onlyOwner {
        require(ERC20(WTAO_ADDRESS).transfer(msg.sender, ERC20(WTAO_ADDRESS).balanceOf(address(this))));
    }
}