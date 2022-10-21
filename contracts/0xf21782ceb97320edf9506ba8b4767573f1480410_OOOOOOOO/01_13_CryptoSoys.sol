//                                                                                                  
//              :JJYJ~    :!       !.     ^7!.   ~7!!!!!7~   .^        ~!.     ::.   ~~          ..   
//      75J.    [email protected]^5P^  .JG!.   5B.    PB!J#^  [email protected]?!!!  !GPB~    75J!.   !GYJ55~ ~JB^  ^P. 7Y5!   
//    :BY^.     [email protected]:::P&.   ^JPJ.Y#.     #[email protected]^     ^@:    5B^ 5#   ~&5~    .&?   [email protected]~  7#!^&? ^@5:    
//    PG        [email protected]&B?^      .J&B:      P#JJ^      ^@^   [email protected]:  J&.    ^Y#:  [email protected]~   5B.   ~&&?   :755:  
//   :@!        .#G :JG?^      ^&~       PB         ^@^   :&J^J#~    .^J&:   7PYJGJ.     B#.   [email protected]  
//   .G57~^~.    JP   :77     :&J        [email protected]        :Y:    ^??J^     ?Y!.      ::.      [email protected]^   :5Y?^   
//     :7??J^                 ~5         .!                                             ??                                                                                                                                                                                                                                              
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB&&@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PY555P#@@@@@@@@@
//@@@@@@@@@@@@@#P55PB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@
//@@@@@@@@@@@@Y:....:^~!?5#@@@@@@@@@@@@@@@@@@@@5JJJ?GPG?7?J&@@@@@@@@@@@@@@@@@@@@@@B5Y5YY5YY5YY5&@@@@@@
//@@@@@@@@@@@Y.:::::^^^:..:[email protected]@@@@@@@@@@@@@@@@@@!^^^^Y55!^^~#@@@@@@@@@@@@@@@@@&#[email protected]@@@@@
//@@@@@@@@@@G::^^^^~~~~~^:::[email protected]@@@@@@@@@@@@@@@@@777?!!!?~~^!&@@@@@@@@@@@@@@@@@PJJJJ?!!!?^[email protected]@@@@
//@@@@@@@@@#^::~~!!!~!!~~:::^&@@@@@@@@@@@@@@@G5~!!!7?!!~~^[email protected]@@@@@@@@@@@@@@@@@5JJJJ!^[email protected]@@@@
//@@@@@@@@@7.::^7!~7!?!7^::::[email protected]@@@@@@@@@@@@@@7~~~~~~!YP#[email protected]@@@@@@@@@@@@@@@@@PJJY?^~~^?Y!Y?7^[email protected]@@@@
//@@@@@@@#7.:::^~~~?7J7^~^:.^&@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@GJJY7^~~~~!?YY?~~JJ#@@@@@
//@@@@@@Y:.:::::^~~!?55!^:.:[email protected]@@@@@@@@@@@@@@@@&~~~^[email protected]@@@?^#@@@@@@@@@@@@@@@@@@#JJY7~~~~^[email protected]@@[email protected]@@@@@
//@@@@@&?^..::::^[email protected]@7^[email protected]@@@@@@@@@@@@@@@@@G^[email protected]@@@G!&@@@@@@@@@@@@@@@@@@@PJY7^~~~^[email protected]@@[email protected]@@@@@
//@@@@@@@&P?!::^~!~~!J7^~&@@@@@@@@@@@@@@@@@@@@P^^^^?&@@@[email protected]@@@@@@@@@@@@@@@@@@@PJJ!~!~^[email protected]@Y?J5#&@@@@
//@@@@@@@@@@J^[email protected]@@@@@@@@@@@@@@@@@@@@G7???~!J5?^[email protected]@@@@@@@@@@@@@@@@@@GJJY?~!77~^~7J5GBYJ5&@@@@
//@@@@@@@@@@J^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~^[email protected]&[email protected]@@@@@@@@@@@@@@@@@@&BB&Y^~^Y#PPGB&@@&[email protected]@@@@@
//@@@@@@@@@@J^~~~~~~~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@J^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@7^~^[email protected]@@@@@@@@@@@@@@@
//@@@@@@@@@@Y^~~~~~~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@7^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@&!^~^[email protected]@@@@@@@@@@@@@@@

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/access/Ownable.sol";

contract OOOOOOOO is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0 ether;
    uint256 public maxSupply = 1001;
    uint256 public maxMintAmount = 1;
    uint256 public maxperwallet = 1;
    bool public paused = false;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;
    mapping(address => uint256) public mintedWallets;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        mint(msg.sender, 1);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        require(mintedWallets[msg.sender] <= maxperwallet, 'exceeds max per wallet');
        mintedWallets[msg.sender] += maxperwallet;

        if (msg.sender != owner()) {
                 {
                    //general public
                    require(msg.value >= cost * _mintAmount);
                
            }
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}