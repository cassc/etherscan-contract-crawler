// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DiamondContract.sol";

contract GameContract is AccessControl{
    using SafeMath for uint256;
    using ECDSA for bytes32;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public SHFTokenAddress;
    Diamond public DiamondTokenAddress;
    address public VaultAddress;
    event UserClaim(uint256 _nonce ,uint256 _rate,uint256 _amount, address claimer);
    struct GameRewards {
        address gamerAddress;
        uint256 claimAmount;
    }
    mapping(bytes32 => GameRewards) public claim;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function setTokenAddress(address _shf, address payable _diamond) public onlyRole(DEFAULT_ADMIN_ROLE) {
        SHFTokenAddress = _shf;
        DiamondTokenAddress = Diamond(_diamond);
    }

    function setVaultAddress(address _vault) public onlyRole(DEFAULT_ADMIN_ROLE){
        VaultAddress = _vault;
    }

    // function mintDiamond(uint256 amount) public onlyRole(MINTER_ROLE){
    //     Diamond(DiamondTokenAddress).mint(address(this), amount);
    // }

    // Get message hash to sign
    function getMessageHash(
        address _gamerAddress,
        uint256 _nonce,
        uint256 _claimAmount,
        uint256 _rate
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_gamerAddress, _nonce, _claimAmount, _rate));
    }

    // claim SFG
    function claimDiamond(
        uint256 _nonce,
        uint256 _claimAmount,
        uint256 _rate,
        bytes memory signature
    ) public {
        bytes32 _hashedNonce = keccak256(abi.encodePacked(_nonce, msg.sender));
        require (!(claim[_hashedNonce].claimAmount > 0), "has claimed");
        // verify signature
        bytes32 messageHash = getMessageHash(msg.sender, _nonce, _claimAmount, _rate);
        require (hasRole(SIGNER_ROLE, messageHash
            .toEthSignedMessageHash()
            .recover(signature)), "signature invalid");

        // transfer token.
        DiamondTokenAddress.transfer(msg.sender, _claimAmount * _rate);
        ERC20(SHFTokenAddress).transferFrom(msg.sender, VaultAddress, _claimAmount);

        claim[_hashedNonce] = GameRewards(msg.sender, _claimAmount);
        emit UserClaim(_nonce,_rate,_claimAmount ,msg.sender);
    }
}