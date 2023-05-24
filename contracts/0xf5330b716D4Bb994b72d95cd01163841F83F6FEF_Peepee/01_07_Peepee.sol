// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./Pepeable.sol";
import "./IERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/*
* @title Strings
*/
contract Peepee is ERC20, Pepeable {

    uint public MAX_SUPPLY = 420000000000 ether;
    uint public CLAIMABLE_TOTAL = 42000000000 ether;
    uint public CLAIMABLE_PER = 6026689.6254842875591907 ether;
    uint public TOTAL_PEEPEE_2DS = 6969;
    uint public MAX_BUY_LIMIT = 4200000000 ether;
    bool public tradingOpen = false;
    bool public limitEnabled = true;
    address public uniswapPair;
    mapping(uint => bool) public claimed;
    mapping(address => bool) public holderClaimed;
    mapping(address => bool) public exemptAddresses;
    IERC721A public pepe2d;

    // Claiming for 2D Owners
    function claim(uint[] calldata _tokenIds) external {
        require(tradingOpen, "Trading is not open");
        require(!holderClaimed[msg.sender], "Already claimed");

        uint tokensToClaim = 0;

        for(uint i = 0;i<_tokenIds.length;i++){
            if(pepe2d.ownerOf(_tokenIds[i]) == msg.sender && !claimed[_tokenIds[i]]){
                claimed[_tokenIds[i]] = true;
                tokensToClaim += CLAIMABLE_PER;
            }
        }
        
        require(totalSupply() + tokensToClaim <= MAX_SUPPLY, "Too many tokens minted");

        holderClaimed[msg.sender] = true;
        _mint(msg.sender,tokensToClaim);
    }

    function setTrading(bool _status) external onlyPepe {
        tradingOpen = _status;
    }

    function setLimits(bool _status) external onlyPepe {
        limitEnabled = _status;
    }

    function setMaxBuy(uint _amount) external onlyPepe {
        MAX_BUY_LIMIT = _amount;
    }

    function setPair(address _ca) external onlyPepe {
        uniswapPair = _ca;
    }

    function setPepe2d(address _ca) external onlyPepe {
        pepe2d = IERC721A(_ca);
    }
    
    function addExemptAddress(address _address) external onlyPepe {
        exemptAddresses[_address] = true;
    }
    
    function removeExemptAddress(address _address) external onlyPepe {
        exemptAddresses[_address] = false;
    }

    
    function rescueUnclaimed() external onlyPepe {
        _mint(msg.sender, (MAX_SUPPLY-totalSupply()));
    }


    function getOwnedPeepees(address _holder) external view returns(uint[] memory) {
        uint tokenCount = pepe2d.balanceOf(_holder);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for(uint i=1;i<=TOTAL_PEEPEE_2DS;i++) {
                if(pepe2d.ownerOf(i) == _holder){
                    result[index] = i;
                    index += 1;
                }
            }
            return result;
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(exemptAddresses[from] || exemptAddresses[to]){
           // Owner can send and receive tokens any time.
        }else{
            require(tradingOpen, "Trading is not open");
            if(limitEnabled && from == uniswapPair){
                require(balanceOf(to) + amount <= MAX_BUY_LIMIT, "Cannot hold more in your wallet");
            }
        }
    }
    

    constructor() ERC20("peepee", "peepee") {
        exemptAddresses[msg.sender] = true;
        pepe2d = IERC721A(0x08dbE010BF723B334ed62e3c6F2d227731806C9E);
        _mint(msg.sender, (MAX_SUPPLY-CLAIMABLE_TOTAL));
    }

}