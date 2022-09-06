/*    ____  __  ____  ___   ____ __    __________  ____  ____________   ___
    / __ \/ / / / / / / | / / //_/   / ____/ __ \/ __ \/ ____/ ____/  <  /
   / /_/ / /_/ / / / /  |/ / ,<     / /_  / / / / /_/ / /   / __/     / / 
  / ____/ __  / /_/ / /|  / /| |   / __/ / /_/ / _, _/ /___/ /___    / /  
 /_/   /_/ /_/\____/_/ |_/_/ |_|  /_/    \____/_/ |_|\____/_____/   /_/  V2 by TEJI
*/                                                          
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../contracts/ERC721K.sol";

contract PhunkForce1V2 is Ownable, ERC721K {

    uint256 public nextIndexToAssign = 0;
    uint256 private mintPrice = 0.2 ether;
    uint256 private discountPrice = 0.1 ether;
    bool public mintState = false;

    //existing contracts for discount
    IERC721 private tejiverse = ERC721(0x74FDce4a5AbAA0c8C6933e80Ad4fEc50A0270D11);
    IERC721 private nhike = ERC721(0x28D0a1D3125f9132Efa6C1c09Ab446b8c63f3dDf);
    IERC721 private phlv = ERC721(0xA3088D8a04071974b86f910A4058f077aC34D386);
    IERC721 private rrt = ERC721(0x28BE4f6E3B41e483A0bbaD5e52A1e0af1cabCDAa);
    IERC721 private philips = ERC721(0xA82F3a61F002F83Eba7D184c50bB2a8B359cA1cE);
    IERC721 private v1phunks = ERC721(0x235d49774139c218034c0571Ba8f717773eDD923);
    IERC721 private v2phunks = ERC721(0xf07468eAd8cf26c752C676E43C814FEe9c8CF402);
    IERC721 private v3phunks = ERC721(0xb7D405BEE01C70A9577316C1B9C2505F146e8842);
    IERC721 private notV1phunks = ERC721(0x3ceB6868BfBf99F6b76FE5bB37343C075677C698);
    IERC721 private v1punks = ERC721(0x282BDD42f4eb70e7A9D9F40c8fEA0825B7f68C5D);
    IERC20 private v2punks = ERC20(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    
    mapping(address => bool) private _allowList;
    address[] private whiteList;

    constructor() ERC721K("PHUNK FORCE 1 V2 by TEJI", "CPLVN") {}

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
        require (super.totalSupply() < 447, "No mints remaining");

        _allowList[msg.sender] = false;
        super._mint(msg.sender, nextIndexToAssign);
        nextIndexToAssign++;
    }

    function publicMint(uint _amount) public payable {
        require (mintState, "Mint is not active");
        require (_amount < 6, "Quantity exceeded. Maximum is 5");
        require (_amount + super.totalSupply() <= 447, "No mints remaining");
        
        if (tejiverse.balanceOf(msg.sender) > 0 ||
            nhike.balanceOf(msg.sender) > 0 ||
            phlv.balanceOf(msg.sender) > 0 ||
            philips.balanceOf(msg.sender) > 0 ||
            v1phunks.balanceOf(msg.sender) > 0 ||
            v2phunks.balanceOf(msg.sender) > 0 ||
            v3phunks.balanceOf(msg.sender) > 0 ||
            v1punks.balanceOf(msg.sender) > 0 ||
            rrt.balanceOf(msg.sender) > 0 ||
            notV1phunks.balanceOf(msg.sender) > 0 ||
            v2punks.balanceOf(msg.sender) > 0) {

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
        
        Address.sendValue(payable(saintmaxiAddress), five);
        Address.sendValue(payable(kenobiAddress), ten);
        Address.sendValue(payable(tejiAddress), total - (ten + five));
    }
}