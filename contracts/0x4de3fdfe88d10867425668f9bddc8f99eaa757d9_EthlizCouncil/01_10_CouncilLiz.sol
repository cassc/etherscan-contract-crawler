// SPDX-License-Identifier: MIT

/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
                            @@##%@@                                                                                 
                             @%&(((((@@#(((((&@                                                                         
                     #@@@           @(#**@*@*@/#@                                                                       
                   @@              /#/*@**@****(@&@@                                                                    
                  @@  @.            @(@**@/@*@/#@    &@                                                                 
                   @ .  @@.          @@#(///(#@         @@                                                              
                   @@....   @@,                           @                                                             
                    @@.....      @@@@                      @                                                            
                      @......    @ @,                       @@                                                          
                        @... . .                             @@                                                         
                          @@.....                             &@                                                        
                            @@.......                          (@                                                       
                               @@.......                         @.                                                     
                                 @@.......                         @                                                    
                                     @@....                          @.                                                 
                                        @@... .                        @@                                               
                                          @@.... .                        @@                                            
                                            @.......                          @@                                        
                                             @.........                           @@                                    
                                             @@..........                             @@                                
                                             @@.............             @@@@            @@                             
                                             @.................                (@@          @#                          
                                            @@.................                    @@         @@                        
                                           @@................... @,                  &@         @@                      
                                          @*.....*@[email protected]                 @@         @@                    
                                         @[email protected]@@                  @          @.                  
                                        @[email protected]@@.              @          /@                 
                                      &@[email protected]@@@.......................  @@@@       @,           @                
                                     @@[email protected]@    @@...................... .  @       %@            @               
                                    [email protected]@.       *@...................... [email protected]       @@             @              
                                    @@[email protected]            ,@@[email protected]     @               @(            
@@@@@@@@@  @@@@@@@@@@@  @%      [email protected]        @@         @@   @@@@@@@@@&     @@@      @@@@@@@@@@    @@@@@@@@      #@@@@@@@  
@.              @       @%      [email protected]        @@         @@         @@      @@ @@     @@       @@   @@      @@   @@      @@ 
@@@@@@@@@       @       @@@@@@@@@@        @@         @@       @@       @@   @@    @@    [email protected]@@    @@       @@   @@@@@@    
@.              @       @%      [email protected]        @@         @@     @@        @@@@@@@@@   @@    @@@     @@       @@          @@ 
@.              @       @%      [email protected]        @@         @@   @@         @@       @@  @@      @@    @@      @@   @@      %@ 
@@@@@@@@@@      @       @%      [email protected]        @@@@@@@@@  @@  @@@@@@@@@@@@@         @@ @@        @@  @@@@@#          @@@@(   
                                                                                                                        
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +

Contract: Ethlizards Council ERC1155 Contract
Web: ethlizards.io
Underground Lizard Lounge Discord: https://discord.com/invite/ethlizards
Developer: Sp1cySauce - Discord: SpicySauce#1615 - Twitter: @SaucyCrypto

*/

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract EthlizCouncil is ERC1155, Ownable {
    string public name;
    string public symbol;

    mapping(uint256 => string) public tokenURI;
    mapping(address => bool) public projectProxy;
    mapping(address => bool) public allowList;

    address public proxyRegistryAddress;
    bool locked;

    constructor(address _proxyRegistryAddress) ERC1155("") {
        name = "EthlizCouncil";
        symbol = "COUNCILLIZ";
        proxyRegistryAddress = _proxyRegistryAddress;
    }

     function setLocked(bool _locked) external {
        locked = _locked;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function flipallowListState(address allowAddress) public onlyOwner {
        allowList[allowAddress] = !allowList[allowAddress];
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(!locked, "Cannot transfer - currently locked");
        require(allowList[to], "Cannot transfer - Not Authorized");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}