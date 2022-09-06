// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
                                                                          
//  ______     ______     ______   ______     ______     ______   ______     __         ______    
// /\  __ \   /\  ___\   /\__  _\ /\  == \   /\  __ \   /\  == \ /\  __ \   /\ \       /\  ___\   
// \ \  __ \  \ \___  \  \/_/\ \/ \ \  __<   \ \ \/\ \  \ \  _-/ \ \  __ \  \ \ \____  \ \___  \  
//  \ \_\ \_\  \/\_____\    \ \_\  \ \_\ \_\  \ \_____\  \ \_\    \ \_\ \_\  \ \_____\  \/\_____\ 
//   \/_/\/_/   \/_____/     \/_/   \/_/ /_/   \/_____/   \/_/     \/_/\/_/   \/_____/   \/_____/ 
                                                                                               

contract AstroPals is Ownable, ERC721A {
    uint256 public constant MAX_PALS = 4444;
    uint256 public constant MAX_PALS_PER_WALLET = 5;
    uint256 public constant PALS_PER_TX = 5;
    uint256 public constant PRICE = 0.009 ether;

    address private constant HOME_BASE_ADDRESS =
        0x5d2Afc246857F318B85541435592572489D3062e;

    bool public isLaunched = false;

    constructor() ERC721A("AstroPals", "APAL") {}

    function mint(uint256 _amount) external payable {
        require(tx.origin == msg.sender, "beep boop");
        require(isLaunched, "Not launched");
        require(_amount <= PALS_PER_TX, "Exceeds per transaction");
        require(_totalMinted() + _amount <= MAX_PALS, "Exceeds supply");
        require(PRICE * _amount <= msg.value, "Incorrect ETH value");

        uint64 _walletMinted = _getAux(msg.sender);
        require(_walletMinted + _amount <= MAX_PALS_PER_WALLET, "Exceeds amount per wallet");

        _setAux(msg.sender, uint64(_amount));
        _mint(msg.sender, _amount);
    }

    function toggleLaunch() external onlyOwner {
        isLaunched = !isLaunched;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Withdraw: Insufficient ETH");

        _withdraw(HOME_BASE_ADDRESS, ((balance * 125) / 1000));
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Withdraw: Failed");
    }
}