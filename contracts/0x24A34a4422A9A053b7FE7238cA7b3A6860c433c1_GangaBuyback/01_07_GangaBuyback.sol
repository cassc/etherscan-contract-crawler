// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IGangaNomads.sol";

// @author: olive

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//     ▄████  ▄▄▄       ███▄    █   ▄████  ▄▄▄          ▄▄▄▄    █    ██▓██   ██▓ ▄▄▄▄    ▄▄▄       ▄████▄   ██ ▄█▀    //
//    ██▒ ▀█▒▒████▄     ██ ▀█   █  ██▒ ▀█▒▒████▄       ▓█████▄  ██  ▓██▒▒██  ██▒▓█████▄ ▒████▄    ▒██▀ ▀█   ██▄█▒     //
//   ▒██░▄▄▄░▒██  ▀█▄  ▓██  ▀█ ██▒▒██░▄▄▄░▒██  ▀█▄     ▒██▒ ▄██▓██  ▒██░ ▒██ ██░▒██▒ ▄██▒██  ▀█▄  ▒▓█    ▄ ▓███▄░     //
//   ░▓█  ██▓░██▄▄▄▄██ ▓██▒  ▐▌██▒░▓█  ██▓░██▄▄▄▄██    ▒██░█▀  ▓▓█  ░██░ ░ ▐██▓░▒██░█▀  ░██▄▄▄▄██ ▒▓▓▄ ▄██▒▓██ █▄     //
//   ░▒▓███▀▒ ▓█   ▓██▒▒██░   ▓██░░▒▓███▀▒ ▓█   ▓██▒   ░▓█  ▀█▓▒▒█████▓  ░ ██▒▓░░▓█  ▀█▓ ▓█   ▓██▒▒ ▓███▀ ░▒██▒ █▄    //
//    ░▒   ▒  ▒▒   ▓▒█░░ ▒░   ▒ ▒  ░▒   ▒  ▒▒   ▓▒█░   ░▒▓███▀▒░▒▓▒ ▒ ▒   ██▒▒▒ ░▒▓███▀▒ ▒▒   ▓▒█░░ ░▒ ▒  ░▒ ▒▒ ▓▒    //
//     ░   ░   ▒   ▒▒ ░░ ░░   ░ ▒░  ░   ░   ▒   ▒▒ ░   ▒░▒   ░ ░░▒░ ░ ░ ▓██ ░▒░ ▒░▒   ░   ▒   ▒▒ ░  ░  ▒   ░ ░▒ ▒░    //
//   ░ ░   ░   ░   ▒      ░   ░ ░ ░ ░   ░   ░   ▒       ░    ░  ░░░ ░ ░ ▒ ▒ ░░   ░    ░   ░   ▒   ░        ░ ░░ ░     //
//         ░       ░  ░         ░       ░       ░  ░    ░         ░     ░ ░      ░            ░  ░░ ░      ░  ░       //
//                                                           ░          ░ ░           ░           ░                   //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract GangaBuyback is Ownable, ReentrancyGuard {
    address private signerAddress;

    mapping(address => bool) internal admins;

    address public constant topAdminAddress = 0x5fD345f759E6cE8619d7E3A57444093Fe0b52F66;

    IGangaNomads public gangaNomads;

    event Deposited(uint256 amount);
    event Buyback(address to, uint256 amount);

    constructor(address _signer, IGangaNomads _gangaNomads) {
      admins[msg.sender] = true;
      signerAddress = _signer;
      gangaNomads = _gangaNomads;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'GangaBuyback: Caller is not the admin');
        _;
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function deposit() public payable onlyAdmin {
      require(msg.value > 0, "GangaBuyback: Not a valid amount");
      emit Deposited(msg.value);
    }

    function withdrawSome(uint256 _amount) public onlyAdmin {
      uint256 balance = address(this).balance;
      require(balance > 0 && _amount <= balance);
      _withdraw(topAdminAddress, _amount);
    }

    function withdrawAll() public onlyAdmin {
      uint256 balance = address(this).balance;
      require(balance > 0);
      _withdraw(topAdminAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "GangaBuyback: Transfer failed.");
    }

    function buyback(uint256 _amount, uint256[] calldata _tokenIds, bytes memory _signature) external nonReentrant{
        uint256 balance = address(this).balance;
        require(_amount <= balance, "GangaBuyback: Not enough balance");

        address wallet = _msgSender();
        address signerOwner = signatureWallet(wallet, _amount, _tokenIds, _signature);
        require(signerOwner == signerAddress, "GangaBuyback: Invalid data provided");

        require(_tokenIds.length > 0, "GangaBuyback: Invalid tokenIds");

        for(uint8 i = 0; i < _tokenIds.length; i ++) {
            require(_tokenIds[i] != 0, "Token Id can't be zero.");
            require(
                gangaNomads.ownerOf(_tokenIds[i]) == wallet,
                "GangaBuyback: Caller is not owner."
            );
        }

        gangaNomads.burn(_tokenIds);
        _withdraw(wallet, _amount);
        emit Buyback(wallet, _amount);
    }

    function signatureWallet(address _wallet, uint256 _amount, uint256[] calldata _tokenIds , bytes memory _signature) public pure returns (address){

      return ECDSA.recover(keccak256(abi.encode(_wallet, _amount, _tokenIds)), _signature);

    }

    function updateSignerAddress(address _signer) public onlyOwner {
      signerAddress = _signer;
    }

    function setGangaNomads(IGangaNomads _gangaNomads) public onlyOwner {
        gangaNomads = _gangaNomads;
    }
}