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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IggyPop is ERC1155Burnable, Ownable {
    address public burnTokenAddress = 0x6dDdB0D63f5E12fdb18113916Bb3C6d67688024A;    
    uint256 public burnTokenId = 47; 
    uint256 public burnTokenAmount = 10;

    string public name = "207faces of Iggy - Rainer Hosch";
    string public symbol = "207foi";
    
    string public contractUri = "https://iggy.rainerhosch.com/contract"; 
    
    mapping(address => bool) private _minters;
    
    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() ERC1155("https://iggy.rainerhosch.com/{id}") {
        _idTracker.increment();
    }

    function setBurnToken(address _address, uint256 _tokenId, uint256 _burnAmount) public onlyOwner {
        burnTokenAddress = _address;
        burnTokenId = _tokenId;
        burnTokenAmount = _burnAmount;
    }

    function setMinters(address[] memory _addresses, bool _isMinter) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _minters[_addresses[i]] = _isMinter;
        }
    }

    function isMinter(address _address) public view returns(bool) {
        return _minters[_address];
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
        require(_minters[msg.sender] == true, "Not minter");
        for (uint256 i = 1; i < _idTracker.current(); i++)
            require(balanceOf(msg.sender, i) == 0, "Already minted");

        ERC1155PresetMinterPauser burnTokenToken = ERC1155PresetMinterPauser(burnTokenAddress);

        require(burnTokenToken.balanceOf(msg.sender, burnTokenId) >= burnTokenAmount, "No tokens");
        require(burnTokenToken.isApprovedForAll(msg.sender, address(this)), "Not approved");
        burnTokenToken.burn(msg.sender, burnTokenId, burnTokenAmount);

        _mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();        
        _minters[msg.sender] = false;
    }
}