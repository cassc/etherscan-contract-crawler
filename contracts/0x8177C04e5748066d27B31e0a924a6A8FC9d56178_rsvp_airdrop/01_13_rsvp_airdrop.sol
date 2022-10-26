// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';



contract rsvp_airdrop is ERC1155, Ownable, ERC1155Burnable
{
    using SafeMath for uint8;


    address public cookie_tree = 0x22764243EC635302C080b55de98ECEE0322E815A;
    address public dr_slurp = 0x13ED8515eA47b0B2dc20c7478F839E92b48f6A3b;
    address[] public MyFiBuyers =  [0x844AEA3aD1c43D2e53948DEa6E99983B68073a93, 0x16A7CF1B739fC45d7cEAc90Ad6a7582126Db4B00, 0x6877be9E00d0bc5886c28419901E8cC98C1c2739, 0x113d754Ff2e6Ca9Fd6aB51932493E4F9DabdF596, 0xa6E220D1AD30b194962aB9672328FE7978348C5E, 0x13ED8515eA47b0B2dc20c7478F839E92b48f6A3b, 0xc25a6189D807A2551A6E5bd1D41F4bb52288E1Ae, 0x46a0fE550874211F86bC9dd7F31c5D083DF0eA2c, 0xE72EB31b59F85b19499A0F3b3260011894FA0d65, 0xf7179758F14380C39F444B3dC688773DA6c7a8f7, 0xde70BDf7dfE13614d281716813274380a59E3e5d, 0xB630AbD9a5367763B7CBa316e870c4A54064CC9F, 0xa4c270698166cc206F5656573CCeE9a8E6Ac517d, 0x9Ee498513B382ccE8be6586F1Eb617799eF27073, 0xf48D3E748F97eA7616565fC81B823bCe738C9459, 0x8A05fA58d533a6e40C4381E3247Cf4c68ca61cdc, 0x3e8129adE36b32dEeCeACBbBb89E7dF65433a1a0, 0x9e1b6d2f0CE5fC8b4a820eEDebb6d383cB86a01d, 0x20C467db9B9Fe0fA39D879b3f23c475582Da2Fba, 0x2A9AFb28c5a649Ddd1193825D62deF9C2522b973, 0xB8c7088500A62adE8978659E92388c3Cc331Ad43, 0x71c5eb9C75f44D8C5D276DAE9423C867E6E63a61];
    bool public readyToMint = true;

    string public baseURI;
    string public licenseLink;



    constructor() ERC1155("") 
    {

    }

    function setURI(string memory newuri) public onlyOwner 
    {
	baseURI = newuri;
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function airdrop() public onlyOwner
    {
        if(readyToMint)
        {
            mint(dr_slurp, 0, 2, "");
            mint(cookie_tree, 0, 2, "");

            for(uint8 i=0; i<MyFiBuyers.length; i++)
            {
                mint(MyFiBuyers[i], 0, 1, "");
            }

            readyToMint = false;
        }
    }

  function uri(uint256 tokenID) public view override returns (string memory)
  {
       return string.concat(baseURI,"0.json");
  }

    function setLicenseLink(string memory ll) public onlyOwner
    {
	licenseLink = ll;
    }
}