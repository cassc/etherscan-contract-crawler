// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./IERC721.sol";
import "./ReentrancyGuardUpgradable.sol";
import "./HasRegistration.sol";

contract ClaimedUpgradable is ReentrancyGuardUpgradable, HasRegistration {
    
    bool canClaim;
    mapping(address => bytes32) LegacyClaims;
    mapping(address => bytes32) LegacyClaimsBy;
    mapping(address => mapping(uint => address)) Claims;
    mapping(address => uint256[]) ClaimsFor;
    address[] BurnAddresses;
    
    function initialize() public initializer {
        __Ownable_init();
        ReentrancyGuardUpgradable.init();
        canClaim = true;
        BurnAddresses.push(address(0));
        BurnAddresses.push(0x5D152dd902CC9198B97E5b6Cf5fc23a8e4330180);
    }

    function version() public pure returns (uint256) {
        return 3;
    }
    
    function isBurnAddress(address needle) public view returns (bool) {
        address[] memory burnAddresses = getBurnAddresses();
        for (uint i=0; i < burnAddresses.length; i++) {
            if (burnAddresses[i] == needle) {
                return true;
            }
        }
        return false;
    }

    function toggleCanClaim() public onlyOwner {
        canClaim = !canClaim;
    }
    
    function claim(address nftAddress, uint tokenId, address _claimedBy) public nonReentrant isRegisteredContract(_msgSender()) {        
        if (canClaim) {
            addToClaims(nftAddress, tokenId, _claimedBy);
        } else { 
            revert("Claiming is turned off");
        }
    }
    
    function isClaimed(address nftAddress, uint tokenId, bytes32[] calldata proof ) public view returns(bool) {
        bytes32 _hash = keccak256(abi.encodePacked(tokenId));
        IERC721 token = IERC721(nftAddress);        
        if (proof.length == 0) {
            bool claimed = getClaims(nftAddress, tokenId) != address(0);
            bool addressClaimed = false;
            try token.ownerOf(tokenId) returns (address _owner) {
                if (isBurnAddress(_owner)) {
                    addressClaimed = true;
                }
            } catch {}
            return addressClaimed || claimed;
        } else {
            bytes32 root = getLegacyClaims(nftAddress);
            return verifyScript(root, _hash, proof);
        }
    }

    function getClaimsFor(address _owner) public view returns (uint256[] memory) {
        return ClaimsFor[_owner];
    }

    function getLegacyClaims(address nftAddress) public view returns(bytes32) {
        return LegacyClaims[nftAddress];
    }
    
    function claimedBy(address nftAddress, uint tokenId) public view returns (address _owner, string memory _type) {
        address claimed = getClaims(nftAddress, tokenId);
        if (claimed != address(0)) {
            return (claimed, "record");
        } else {
            return (address(0), "unknown");
        }
    }

    function legacyClaimedBy(address nftAddress, address claimant, uint tokenId, bytes32[] calldata proof) public view returns (address _owner, string memory _type) {
        bytes32 root = getLegacyClaimsBy(nftAddress);
        bytes32 _hash = keccak256(abi.encodePacked(claimant, tokenId));
        require(verifyScript(root, _hash, proof), "invalid proof");
        return (claimant, 'legacy');
    }

    function addLegacy(address nftAddress, bytes32 root) onlyOwner public {
        LegacyClaims[nftAddress] = root;      
    }

    function addLegacyClaimedBy(address nftAddress, bytes32 root) onlyOwner public {
        LegacyClaimsBy[nftAddress] = root;
    }

    function getBurnAddresses() internal view returns (address[] memory){
        return BurnAddresses;
    }

    function getLegacyClaimsBy(address nftAddress) internal view returns(bytes32) {
        return LegacyClaimsBy[nftAddress];
    }
    
    function getClaims(address nftAddress, uint tokenId) internal view returns (address) {
        return Claims[nftAddress][tokenId];
    }
    
    function addToBurnAddresses(address burnAddress) internal onlyOwner {
         BurnAddresses.push(burnAddress);
    }
    
    function addToClaims(address nftAddress, uint tokenId, address _owner) internal {
        Claims[nftAddress][tokenId] = _owner;
        ClaimsFor[_owner].push(tokenId);
    }

    function verifyScript(bytes32 root, bytes32 _hash, bytes32[] calldata proof) public pure returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (_hash <= proofElement) {
                _hash = optihash(_hash, proofElement);
            } else {
                _hash = optihash(proofElement, _hash);
            }
        }
        return _hash == root;
    }
    // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
    function optihash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
        mstore(0x00, a)
        mstore(0x20, b)
        value := keccak256(0x00, 0x40)
        }
    }

}