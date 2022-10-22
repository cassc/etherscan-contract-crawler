// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/[email protected]/token/ERC1155/ERC1155.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract aNFTa is ERC1155, Ownable
{
    
    uint256 public mint_Cost = 0.001 ether;
    uint256 public minted_So_Far = 0;
    uint256 public MAX_Supply = 6000;

    address payowner = msg.sender;

	/// @dev Base token URI used as a prefix by uri().
	string public baseTokenURI;

    constructor() ERC1155("AmaNFTa_Muscaria") 
    {
		baseTokenURI = "https://tan-secret-tiger-14.mypinata.cloud/ipfs/QmRPwaFYuA2tEWBeVsLwj4YhzdpnvD3ZiRCRX6T4oJrNsH/";
		
    }
        

    function setURI(string memory newuri) public onlyOwner 
    {
        _setURI(newuri);
    }

    function mint()
        payable 
        public
    {
        require(msg.value == mint_Cost, "Ether needs to equal 0.001");
        require(minted_So_Far < MAX_Supply, "not enought supply left");
        _mint(msg.sender, 1, 1, "");
        minted_So_Far++;
    }

    function withdraw(uint amount) public onlyOwner returns(bool) 
    {
        require(amount <= address(this).balance);
        payable(payowner).transfer(amount);
        return true;
    }

    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                baseTokenURI,
                Strings.toString(_tokenid)
            )
        );
    }

    function set_baseTokenURI(string memory newBaseTokenURI) public onlyOwner
    {
        baseTokenURI = newBaseTokenURI;
    }

    function contractURI() public pure returns (string memory) 
	{
        return "https://tan-secret-tiger-14.mypinata.cloud/ipfs/QmRk76ztEKSXK1reQT3FLUUEuhZxz3dsjuq4msuoR7dsoU";
	}
}