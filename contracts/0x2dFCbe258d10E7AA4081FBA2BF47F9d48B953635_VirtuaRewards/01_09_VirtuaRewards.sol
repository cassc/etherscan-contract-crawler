// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract VirtuaRewards is AccessControl{

    using ECDSA for bytes32;

    IERC721 NFT;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping (address => brandDetail) private brand;
    mapping (bytes => bool) private signatures;

    struct brandDetail{
        address brandAdmin;
        bool status;
    }

    event rewardClaimed(address indexed _beneficiary, uint256 indexed _tokenId, address indexed _brandContractAddress);
    event brandWhitelisted(address indexed _brandContractAddress, address indexed _adminAddress);
    event whitelistedBrandRemoved(address indexed _brandContractAddress);
    event brandRewardStatus(address indexed _brandContractAddress, bool indexed _status);
    event brandAdminUpdated(address indexed _brandContractAddress, address indexed _adminAddress);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function claimReward(
        address _brandAddress, 
        uint256 _tokenId, 
        bytes32 _msgHash, 
        bytes memory _signature
    ) public {
        require(brand[_brandAddress].brandAdmin != address(0),"Reward Contract: Brand contract not whitelisted!");
        require(brand[_brandAddress].status,"Reward Contract: Brand reward not active!");
        require(!signatures[_signature],"Reward Contract: Signature already used!");

        bytes32 msgHash = getMessageHash(msg.sender, _tokenId, _brandAddress);
        bytes32 signedMsgHash = msgHash.toEthSignedMessageHash();

        require(signedMsgHash == _msgHash,"Reward Contract: Invalid message hash!");
        require(_msgHash.recover(_signature) == brand[_brandAddress].brandAdmin,"Reward Contract: Invalid signer!");

        NFT = IERC721(_brandAddress);
        NFT.mint(msg.sender,_tokenId);

        signatures[_signature] = true;

        emit rewardClaimed(msg.sender,_tokenId,_brandAddress);
    }

    function whitelistBrand(
        address _brandContractAddress,
        address _adminAddress
    ) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Reward Contract: Must have admin role to update.");
        require(_adminAddress != address(0),"Reward Contract: Invalid admin address!");
        require(_brandContractAddress != address(0), "Reward Contract: Invalid brand contract address Address!");
        require(brand[_brandContractAddress].brandAdmin == address(0),"Reward Contract: Brand already exist");

        brand[_brandContractAddress].brandAdmin = _adminAddress;
        brand[_brandContractAddress].status = true;

        emit brandWhitelisted(_brandContractAddress,_adminAddress);
    }
    
    function removeWhitelistedBrand(
        address _brandAddress
    ) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Reward Contract: Must have admin role to update.");
        require(brand[_brandAddress].brandAdmin != address(0),"Reward Contract: Brand does not exist");

        delete brand[_brandAddress];

        emit whitelistedBrandRemoved(_brandAddress);
    }
    
    function brandRewardStatusToggle(
        address _brandAddress, 
        bool _status
    ) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Reward Contract: Must have admin role to update.");
        require(brand[_brandAddress].brandAdmin != address(0),"Reward Contract: Brand does not exist");

        brand[_brandAddress].status = _status;

        emit brandRewardStatus(_brandAddress,_status);
    }

    function updateBrandAdmin(
        address _brandAddress, 
        address _adminAddress
    ) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Reward Contract: Must have admin role to update.");
        require(_adminAddress != address(0),"Reward Contract: Invalid admin address!");
        require(_adminAddress != brand[_brandAddress].brandAdmin,"Reward Contract: Admin address already exists!");
        require(brand[_brandAddress].brandAdmin != address(0),"Reward Contract: Brand does not exist");

        brand[_brandAddress].brandAdmin = _adminAddress;

        emit brandAdminUpdated(_brandAddress,_adminAddress);
    }

    function getBrandDetails(
        address _brandAddress
    ) public view returns(
        address _admin, 
        bool _status
    ){
        _admin = brand[_brandAddress].brandAdmin;
        _status = brand[_brandAddress].status;
    }

    function checkSignatureValidity(
        bytes memory _signature
    ) public view returns(bool){
        return signatures[_signature];
    }

    function getMessageHash(
        address _to,
        uint _tokenId,
        address _brandAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _tokenId, _brandAddress));
    }

}