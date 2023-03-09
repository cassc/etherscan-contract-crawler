import "Guardable/ERC721Guardable.sol";
import "solmate/auth/Owned.sol";
import "./lib/MarauderErrors.sol";
import "./lib/MarauderStructs.sol";
import "./interfaces/INuclearNerds.sol";
import "./interfaces/IWarm.sol";
import "./interfaces/IDelegateCash.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract MadMaraudersOfTheAccidentalApocalypse is ERC721Guardable, Owned {
    address public immutable BOX_O_BAD_GUYS_CONTRACT_ADDRESS;
    address public immutable NERDS_CONTRACT_ADDRESS;

    bool claimOpen;

    IWarm public immutable warm;
    IDelegateCash public immutable delegateCash;
    INuclearNerds private immutable nerds;

    mapping(uint256 => bool) public nerdHasClaimed;
    mapping(uint256 => bool) public berserkersEligibleForClaim;

    // max supply 7843 (1:1 nerds + bonus for berserkers - 900 enforcers - 300 warlords)
    ClaimableTokenDetails public raiderTokenDetails;

    /**
     * @notice max supply 5907 (enforced by MadMarauderBoxOBadGuys contract)
     * ------------------------
     * box supply = 2 * 969
     * a la carte supply = 3069
     * claimable supply = 900
     * ------------------------
     * 2 * 969 + 2069 + 900 = 5907
     * ------------------------
     */
    MintableTokenDetails public enforcerTokenDetails;

    /**
     * @notice max supply 3338 (enforced by MadMarauderBoxOBadGuys contract)
     * ------------------------
     * box supply = 969
     * a la carte supply = 2069
     * claimable supply = 300
     * ------------------------
     * 969 + 3069 + 300 = 3338
     * ------------------------
     */
    MintableTokenDetails public warlordTokenDetails;

    constructor(
      address _mintPassContractAddress,
      address _nerdsContractAddress,
      address _warmWalletContractAddress,
      address _delegateCashContract,
      uint256[43] memory berserkerTokenIds,
      string memory _uri
    ) ERC721Guardable("Marauders Of The Accidental Apocalypse", "MARAUDERS") Owned(msg.sender) {
      BOX_O_BAD_GUYS_CONTRACT_ADDRESS = _mintPassContractAddress;
      NERDS_CONTRACT_ADDRESS = _nerdsContractAddress;
      warm = IWarm(_warmWalletContractAddress);
      delegateCash = IDelegateCash(_delegateCashContract);
      nerds = INuclearNerds(NERDS_CONTRACT_ADDRESS);

      enforcerTokenDetails.startTokenId = enforcerTokenDetails.currentTokenId = 9043;
      warlordTokenDetails.startTokenId = warlordTokenDetails.currentTokenId = 14050;

      raiderTokenDetails.currentBonusTokenId = 9000;
      raiderTokenDetails.maxBonusTokenId = 9042;

      for (uint256 i = 0; i < berserkerTokenIds.length;) {
        berserkersEligibleForClaim[berserkerTokenIds[i]] = true;
        unchecked {++i;}
      }

      baseUri = _uri;
    }

    /**
     * @notice function to claim a raider for each nerd you own
     * @param _tokenIds Nerd IDs to claim for. Must own each nerd token, supports delegation through delegate.cash and warm.xyz
     */
    function claimRaiders(uint256[] calldata _tokenIds) external {
      if (!claimOpen) revert ClaimNotStarted();

      for (uint256 i = 0; i < _tokenIds.length;) {
        uint256 tokenId = _tokenIds[i];
        if (!ownerOrDelegateOf(tokenId)) revert MustOwnMatchingNerd();
        if (nerdHasClaimed[tokenId]) revert AlreadyClaimed();
        nerdHasClaimed[tokenId] = true;
        _mint(msg.sender, tokenId);

        if (berserkersEligibleForClaim[tokenId]) {
          if (raiderTokenDetails.currentBonusTokenId > raiderTokenDetails.maxBonusTokenId) revert AllBerserkersMinted();
          _mint(msg.sender, raiderTokenDetails.currentBonusTokenId);
          unchecked { 
            ++raiderTokenDetails.currentBonusTokenId;
            ++raiderTokenDetails.totalSupply;
          }
        }

        unchecked { 
          ++i;
          ++raiderTokenDetails.totalSupply;
        }
      }
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
      return string(abi.encodePacked(baseUri, _toString(id)));
    }

    /**
     * @notice The total number of minted raiders
     */
    function totalRaiderSupply() public view returns (uint256) {
      return raiderTokenDetails.totalSupply;
    }

    /**
     * @notice The total number of minted enforcers
     */
    function totalEnforcerSupply() public view returns (uint256) {
      return enforcerTokenDetails.currentTokenId - enforcerTokenDetails.startTokenId;
    }

    /**
     * @notice The total number of minted warlords
     */
    function totalWarlordSupply() public view returns (uint256) {
      return warlordTokenDetails.currentTokenId - warlordTokenDetails.startTokenId;
    }

    /**
     * @notice The total number of all minted tokens combined: raiders, enforcers, and warlords.
     */
    function totalSupply() public view returns (uint256) {
      return totalRaiderSupply() + totalEnforcerSupply() + totalWarlordSupply();
    }

    /**
     * @notice Token burn callable by token owner or approved address
     */
    function burn(uint256[] calldata tokenIds) external {
      for (uint256 i = 0; i < tokenIds.length;) {
        address from = ownerOf(tokenIds[i]);

        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[tokenIds[i]]) {
          revert InvalidCaller();
        }

        _burn(tokenIds[i]);
        unchecked { ++i; }
      }
    }

    /**
     * @dev Checks for ownership or delegated ownership of a given token. Supports Warm and Delegate.cash
     */
    function ownerOrDelegateOf(uint256 tokenId) internal view returns (bool) {
      return
        msg.sender == nerds.ownerOf(tokenId) ||
        delegateCash.checkDelegateForToken(msg.sender, nerds.ownerOf(tokenId), NERDS_CONTRACT_ADDRESS, tokenId) ||
        msg.sender == warm.ownerOf(NERDS_CONTRACT_ADDRESS, tokenId);
    }

    /* BOX FUNCTIONS (callable from Box Of Bad Guys contract) */

    function mintFromBox(address recipient, uint256 amount) external onlyBox {
      _mint(enforcerTokenDetails, amount * 2, recipient);
      _mint(warlordTokenDetails, amount, recipient);
    }

    function mintEnforcer(address recipient, uint256 amount) external onlyBox {
      _mint(enforcerTokenDetails, amount, recipient);
    }

    function mintWarlord(address recipient, uint256 amount) external onlyBox {
      _mint(warlordTokenDetails, amount, recipient);
    }

    modifier onlyBox {
      if (msg.sender != BOX_O_BAD_GUYS_CONTRACT_ADDRESS) revert InvalidCaller();
      _;
    }

    /* ADMIN FUNCTIONS */

    function setBaseURI(string memory _uri) external onlyOwner {
      baseUri = _uri;
    }

    function setClaimStatus(bool status) external onlyOwner {
      claimOpen = status;
    }

    /* INTERNAL HELPERS */

    function _mint(MintableTokenDetails storage tokenDetails, uint256 amount, address recipient) internal {
      for (uint256 i = 0; i < amount;) {
        _mint(recipient, tokenDetails.currentTokenId);
        unchecked { 
          ++tokenDetails.currentTokenId;
          ++i; 
        }
      }
    }
}