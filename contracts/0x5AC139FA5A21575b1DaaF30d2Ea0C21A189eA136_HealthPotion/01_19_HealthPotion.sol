// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC721.sol";
import "Pausable.sol";
import "IERC20.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";
import "Counters.sol";
import "ReentrancyGuard.sol";
import "Strings.sol"; 

import "Authorized.sol";
import "Policy.sol";


//   _   _            _ _   _       ____       _   _                     ____  
//  | | | | ___  __ _| | |_| |__   |  _ \ ___ | |_(_) ___  _ __   __   _|___ \ 
//  | |_| |/ _ \/ _` | | __| '_ \  | |_) / _ \| __| |/ _ \| '_ \  \ \ / / __) |
//  |  _  |  __| (_| | | |_| | | | |  __| (_) | |_| | (_) | | | |  \ V / / __/ 
//  |_| |_|\___|\__,_|_|\__|_| |_| |_|   \___/ \__|_|\___/|_| |_|   \_/ |_____|
//
// Migration from v1: 0x81BB1A001C3260Bd69008fafF392570E58B68e45
// All existing tokens from v1 were migrated to this contract
// Added support for upcoming features, better policy visibility & fixed some minor aesthetic issues


/// @title An ERC721 contract for the Health Potion upper limit coverage policy
/// @author @flatpackfintech
/// @notice Soulbound Token (whilst active) that records policy details of user wallet protection
/// @dev Inherits the OpenZepplin Ownable module via Authorized.sol
contract HealthPotion is ERC721, Pausable, ERC721Burnable, Authorized, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 private _burned;
    string private _baseURIextended;
    mapping (uint256 => Policy.Cover) public policyTerms;       // TokenID: Policy Terms
    IERC20 public usdcContract;
    address public capitalVaultAddress;                         // Address that stores Capital-at-Risk
    uint256 public totalETHPolicies;                            // Total of ETH policies that have not been burned
    uint256 public totalUSDCPolicies;                           // Total of USDC policies that have not been burned

    event Minted(address indexed owner, uint256 tokenId);
    event Revoked(address indexed owner, uint256 tokenId);

    constructor(address _usdcAddress, address _capitalVaultAddress) ERC721("Health Potion V2", "HP") {
        usdcContract = IERC20(_usdcAddress);
        capitalVaultAddress = _capitalVaultAddress;
        _burned = 0;
    }

    /// @notice Withdraws USDC tokens
    /// @dev Contract should not receive any tokens, this is a fallback
    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        usdcContract.transfer(_to, _amount);
    }

    /// @notice Withdraws ETH
    /// @dev Contract should not receive any ETH, this is a fallback
    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    /// @notice Replicate already minted tokens from existing contract to new version
    /// @param _addresses Array of addresses in order of tokenID
    /// @param _policyDays Array of Policy Days in order of tokenID
    /// @param _policyTypes Array of Policy Types in order of tokenID
    /// @param _startTimestamps Array of starting UNIX timestamps in order of tokenID
    function migrateTokens(
        address[] calldata _addresses, 
        uint256[] calldata _policyDays, 
        Policy.PolicyType[] calldata _policyTypes, 
        uint256[] calldata _startTimestamps
    )
        external 
        onlyOwner
    {
        require(totalSupply() == 0, "Can only migrate to an empty contract.");
        for (uint i = 0; i < _addresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_addresses[i], tokenId);
            policyTerms[tokenId].startTimestamp = _startTimestamps[i];
            policyTerms[tokenId].endTimestamp = _startTimestamps[i] + (_policyDays[i] * 1 days);
            policyTerms[tokenId].lengthDays = _policyDays[i];
            policyTerms[tokenId].paymentType = _policyTypes[i];

            if (_policyTypes[i] == Policy.PolicyType.ETH) {
                totalETHPolicies++;
            } else if (_policyTypes[i] == Policy.PolicyType.USDC) {
                totalUSDCPolicies++;
            }
        }
    }

    /// @notice Checks whether token exists
    /// @param tokenId ID of token
    /// @return true if token ID has been minted and not burned
    function isValid(uint256 tokenId) 
        external 
        view 
        returns (bool) 
    {
        return _ownerOf(tokenId) != address(0);
    }

    /// @notice Checks whether owner holds a token
    /// @param owner Address being checked
    /// @return true if address holds a token (but could be expired or active!)
    function hasValid(address owner) 
        external 
        view 
        returns (bool) 
    {
        return balanceOf(owner) > 0;
    }

    /// @notice Checks whether token is an active policy
    /// @param tokenId ID of token being checked
    /// @return true if current block timestamp is between start and finish of policy timestamps
    function isActive(uint256 tokenId) 
        public 
        view 
        returns (bool) 
    {
        Policy.Cover memory policy = policyTerms[tokenId];
        return(policy.startTimestamp <= block.timestamp && block.timestamp < policy.startTimestamp + policy.lengthDays * 1 days);
    }

    /// @notice Mint a new token (policy)
    /// @dev Should be called by the Minter contract (authorized) in most instances
    /// @param to Array of addresses in order of tokenID
    /// @param _policyDays Number of days in policy
    /// @param _policyType Type of policy (ETH or USDC)
    function safeMint(
        address to, 
        uint256 _policyDays, 
        Policy.PolicyType _policyType
    ) 
        public 
        onlyAuthorized 
        nonReentrant 
    {
        require(balanceOf(to) == 0, "Can only mint one token per wallet");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        policyTerms[tokenId].startTimestamp = block.timestamp;
        policyTerms[tokenId].endTimestamp = block.timestamp + (_policyDays * 1 days);
        policyTerms[tokenId].lengthDays = _policyDays;
        policyTerms[tokenId].paymentType = _policyType;

        if (_policyType == Policy.PolicyType.ETH) {
            totalETHPolicies++;
        } else if (_policyType == Policy.PolicyType.USDC) {
            totalUSDCPolicies++;
        }
    }

    /// @notice Re-activate an existing policy that has expired
    /// @dev Should be called by the Minter contract (authorized) in all instances
    /// @param tokenId ID of token to re-activate
    /// @param _policyDays Number of days of new reactivated policy
    /// @param _policyType Type of policy (ETH or USDC)
    function refill(
        uint256 tokenId, 
        uint256 _policyDays, 
        Policy.PolicyType _policyType
    )
        public 
        onlyAuthorized 
        nonReentrant
    {
        require(!isActive(tokenId), "Policy is still active! Cannot refill until the policy has expired.");
        require(_ownerOf(tokenId) != address(0), "Policy must be minted to refill.");
        policyTerms[tokenId].startTimestamp = block.timestamp;
        policyTerms[tokenId].endTimestamp = block.timestamp + (_policyDays * 1 days);
        policyTerms[tokenId].lengthDays = _policyDays;
        policyTerms[tokenId].paymentType = _policyType;
    }

    /// @notice Burn a policy
    /// @dev Only called by owner once a claim has been completed successfully
    /// @param tokenId ID of token to re-activate
    function burn(uint256 tokenId) 
        public 
        override 
        onlyOwner 
    {
        _burn(tokenId);
        _burned++;  // Total supply decrease

        Policy.Cover memory policy = policyTerms[tokenId];  // Decrease individual policy total
        if (policy.paymentType == Policy.PolicyType.ETH){
            totalETHPolicies--;
        } else if (policy.paymentType == Policy.PolicyType.USDC) {
            totalUSDCPolicies--;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current() - _burned;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract.json")) : "https://www.healthpotion.xyz/api/contract.json";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() 
        internal 
        view 
        override 
        returns (string memory) 
    {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        if (from != address(0) && to != address(0)){    // Can only transfer between wallets when the policy is expired
            require(isActive(tokenId) == false, "Not allowed to transfer token whilst policy is active");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) 
        internal
        override
        virtual 
    {
        if (from == address(0)) {
            emit Minted(to, firstTokenId);
        } else if (to == address(0)) {
            emit Revoked(from, firstTokenId);
        }
    }

}