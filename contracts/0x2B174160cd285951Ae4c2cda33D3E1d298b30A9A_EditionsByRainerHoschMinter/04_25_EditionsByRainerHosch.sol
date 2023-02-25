//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract EditionsByRainerHosch is ERC1155Burnable, Ownable, DefaultOperatorFilterer {
    address public burnTokenAddress = 0x6dDdB0D63f5E12fdb18113916Bb3C6d67688024A;    
    uint256 public burnTokenId = 47; 
    uint256 public burnTokenAmount = 3;

    string public name = "Editions by Rainer Hosch";
    string public symbol = "ERH";
    
    bool public isBurnMintEnabled = true;
    bool public isPayableMintEnabled = false;

    uint256 public mintId = 1; 
    uint256 public price;

    string public contractUri = "https://metadata.rainerhosch.com/editions/contract.json"; 

    constructor() ERC1155("https://metadata.rainerhosch.com/editions/{id}") {
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setIsBurnMintEnabled(bool isEnabled) public onlyOwner {
        isBurnMintEnabled = isEnabled;
    }

     function setIsPayableMintEnabled(bool isEnabled) public onlyOwner {
        isPayableMintEnabled = isEnabled;
    }


    function setMintId(uint256 id) public onlyOwner {
        mintId = id;
    }

    function setBurnToken(address _address, uint256 _tokenId, uint256 _burnAmount) public onlyOwner {
        burnTokenAddress = _address;
        burnTokenId = _tokenId;
        burnTokenAmount = _burnAmount;
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
    }

    function mint() public {
        require(isBurnMintEnabled, "Mint not enabled");
        
        ERC1155PresetMinterPauser burnTokenToken = ERC1155PresetMinterPauser(burnTokenAddress);

        require(burnTokenToken.balanceOf(msg.sender, burnTokenId) >= burnTokenAmount, "No tokens to burn");
        require(burnTokenToken.isApprovedForAll(msg.sender, address(this)), "Not approved");
        burnTokenToken.burn(msg.sender, burnTokenId, burnTokenAmount);

        _mint(msg.sender, mintId, 1, "");
    }

     function mint(uint256 amount) public payable {
        require(isPayableMintEnabled, "Mint not enabled");
        require(msg.value >= price * amount, "Not enough eth");

       _mint(msg.sender, mintId, amount, ""); 
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}