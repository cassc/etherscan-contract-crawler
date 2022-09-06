/*    ____  __  ____  ___   ____ __    __________  ____  ____________   ___
    / __ \/ / / / / / / | / / //_/   / ____/ __ \/ __ \/ ____/ ____/  <  /
   / /_/ / /_/ / / / /  |/ / ,<     / /_  / / / / /_/ / /   / __/     / / 
  / ____/ __  / /_/ / /|  / /| |   / __/ / /_/ / _, _/ /___/ /___    / /  
 /_/   /_/ /_/\____/_/ |_/_/ |_|  /_/    \____/_/ |_|\____/_____/   /_/  by TEJI
*/                                                          
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/ERC721K.sol";

contract PhunkForce1 is Ownable, ERC721K {

    uint256 public nextIndexToAssign = 0;
    uint256 private mintPrice = 0.2 ether;
    uint256 private discountPrice = 0.1 ether;
    bool public mintState = false;

    //existing contracts for discount
    IERC721 private tejiverse = ERC721(0x74FDce4a5AbAA0c8C6933e80Ad4fEc50A0270D11);
    IERC721 private nhike = ERC721(0x28D0a1D3125f9132Efa6C1c09Ab446b8c63f3dDf);
    IERC721 private phlv = ERC721(0xA3088D8a04071974b86f910A4058f077aC34D386);
    IERC721 private rrt = ERC721(0x28BE4f6E3B41e483A0bbaD5e52A1e0af1cabCDAa);
    IERC721 private phunks = ERC721(0xf07468eAd8cf26c752C676E43C814FEe9c8CF402);
    

    mapping(address => bool) private _allowList;
    address[] private whiteList;

    constructor() ERC721K("PHUNK FORCE 1 by TEJI", "CPLVN") {}

    function flipMintState() public onlyOwner {
        mintState = !mintState;
    }
    
    function setWhiteList(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
            whiteList.push(addresses[i]);
        }
    }

    function getWhiteList() external view returns (address[] memory){
        return whiteList;

    }
    
    function whiteListMint() external {
        require (mintState, "Mint is not active");
        require (_allowList[msg.sender] == true, "not on whitelist");
        require (super.totalSupply() < 500, "No mints remaining");

        _allowList[msg.sender] = false;
        super._mint(msg.sender, nextIndexToAssign);
        nextIndexToAssign++;
    
    }

    function mint(uint _amount) public payable {
        require (mintState, "Mint is not active");
        require (_amount < 6, "Quantity exceeded. Maximum is 5");
        require (super.totalSupply() < 500, "No mints remaining");
        
        if (tejiverse.balanceOf(msg.sender) > 0 ||
            nhike.balanceOf(msg.sender) > 0 ||
            phlv.balanceOf(msg.sender) > 0 ||
            phunks.balanceOf(msg.sender) > 0 ||
            rrt.balanceOf(msg.sender) > 0) {

            require(msg.value == (discountPrice * _amount), "Exact payment is required");

            for (uint i; i < _amount; i++) {
                super._mint(msg.sender, nextIndexToAssign);
                nextIndexToAssign++;
            }

        } else {
            require(msg.value == (mintPrice * _amount), "Exact payment is required");

            for (uint i; i < _amount; i++) {
                super._mint(msg.sender, nextIndexToAssign);
                nextIndexToAssign++;
            }

        }
        
    }
    
    address constant tejiAddress = 0xBacA88029D2b4c3E7e06af8E5d7dF2E3AC8C46c9;
    address constant kenobiAddress = 0x68b6Ba6385a5d395c1ff73c79c9cB2bD2D614dBC;
    address constant saintmaxiAddress = 0x70E93674A2f0eE65a5f16baDa5B13952C6671188;

    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");

        uint total = address(this).balance;
        
        uint five = (total * 5) / 100;
        uint ten = (total * 10) / 100;
        
        Address.sendValue(payable(saintmaxiAddress), five); // 5% to saintmaxi
        Address.sendValue(payable(kenobiAddress), ten); // 10% of mint to kenobi
        Address.sendValue(payable(tejiAddress), total - (ten + five)); //85% of mint to Teji
        
    }
}