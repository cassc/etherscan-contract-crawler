// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTProxy {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    function balanceOf(address owner) public view virtual returns (uint256) {}

    function howManyBorp() public view virtual returns (uint256) {}
}

contract VanBorp is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;

    string public baseTokenURI;
    uint256 public mintPrice = 0.055 ether;
    uint256 public collectionSize = 4970;
    uint256 public reservedSize = 35;
    uint256 public maxPerTx = 15;

    bool public whitelistSaleActive;
    bool public regularSaleActive;
    bool public whitelistRequired = true;

    mapping(uint256 => uint256[3]) internal traits;

    mapping(uint256 => bool) public borpacassoUsed;
    mapping(uint256 => bool) public borpiUsed;

    mapping(address => uint256) public whitelist;

    address private constant borpFanOne =
        0xF90783F6B1265fa13D5510424A77ad5751FcC87e;
    address private constant borpFanTwo =
        0x8eCa6171074D95daF93F2165c472Cb2eb7032458;

    address private constant borpacassoAddress =
        0x370108CF39555e561353B20ECF1eAae89bEb72ce;
    address private constant borpiAddress =
        0xeEABfab26ad5c650765b124C685A13800e52B9d2;

    address[] private nftAddresses = [
        address(0),
        0xf07468eAd8cf26c752C676E43C814FEe9c8CF402, //Phunks
        0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6, //Cryptoadz
        0x95784F7b5c8849b0104EAf5D13d6341d8CC40750, //Swampverse
        0x7caE7B9b9a235D1D94102598E1f23310A0618914, //CROAKZ
        0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB, //Dickbutts
        0xf1BdFC38b0089097f050141d21f5E8a3cb0Ec8FC, //Titvags
        0x8ed25B735A788f4f7129Db736FC64f3A241137B8, //Bears 1
        0x488C057CF3deE9Ee2E386112e08F2c6d8e58cdFB, //Bears 2
        0x279f1ABB8649eA5AF64AFACC6511cb41f512bEC1, //Bears 3
        0x12C4f45ae12B7B8462dB2409488d976995Ab6FE9  //Borphol
    ];

    constructor() ERC721A("Vincent Van Borp", "BORP3") {
        _safeMint(borpFanOne, 6);
    } //Mint 4 nudes UwU, and two ports from v0

    //🐸🐸🐸🐸🐸🐸🐸🐸 MODIFIERS
    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender() {
        _onlySender();
        _;
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 BOOL FLIPPERS

    function flipWhitelistSaleActive() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function flipRegularSaleActive() public onlyOwner {
        regularSaleActive = !regularSaleActive;
    }

    function flipWhitelistRequired() public onlyOwner {
        whitelistRequired = !whitelistRequired;
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 Interface METHODS
    function NFTBalance(
        address owner,
        address nft,
        uint256 id
    ) public view returns (bool) {
        NFTProxy sd = NFTProxy(nft);
        return (owner == sd.ownerOf(id));
    }

    function NFTOwnAny(address owner, address nft) public view returns (bool) {
        NFTProxy sd = NFTProxy(nft);
        return (sd.balanceOf(owner) > 0);
    }

        function NFTList(address owner)
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory _NFTS = new uint256[](nftAddresses.length);
        uint256 j;

        for (uint256 i = 1; i < nftAddresses.length; i++) {
            if (NFTOwnAny(owner, nftAddresses[i]) == true) {
                _NFTS[j] = i;
                j++;
            }
        }

        return (_NFTS, j);
    }

  function borpasLeft(uint256[] memory _borps)
        external
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        uint256[] memory arr = new uint256[](_borps.length);        

        uint256 j;
        uint256 k;
        uint256 breakpoint;

        for (uint256 i = 0; i < _borps.length; i++) {
            if(_borps[i]>10000){
                break;
            }
            breakpoint++;
            if (!borpacassoUsed[_borps[i]]) {
                arr[j] = _borps[i];
                j++;
                k++;
            }
        }
            for (uint256 i = breakpoint; i < _borps.length; i++) {
            if(_borps[i]<=10000){
                break;
            }
            if (!borpiUsed[_borps[i]-10000]){
                arr[k] = _borps[i];
                k++;
            }
        }
        return (arr, j,k);
    }

      function borpaInventory(address owner, bool borp, uint256 start, uint256 end)
        external
        view
        returns (uint256[] memory, uint256)
    {

        address nft;
        uint256 shift;
        //false for Borpacasso, true for Borpi
        borp ? nft = borpiAddress : nft = borpacassoAddress;

        if(borp){shift =10000;}

        NFTProxy sd = NFTProxy(nft);     

        uint256 _balance = sd.balanceOf(owner);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;        

        for (uint256 i = start; i < end; i++) {            
            if (sd.ownerOf(i) == owner) {
                _tokens[_index] = i+shift;
                _index++;
            }
        }
        return (_tokens, _index);
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 WHITELIST STUFF
    function addToWhitelist(address[] memory _address, uint256 _amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = _amount;
        }
    }

    function removeFromWhitelist(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = 0;
        }
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 GIVEAWAY MINT
    function mintGiveawayBorps(uint256 amount) external onlyOwner {
        require(amount <= reservedSize);
        require((totalSupply() + amount) <= collectionSize);
        _safeMint(msg.sender, amount);
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 REGULAR MINT
    function regularMint(uint256 amount, uint256[] memory _borps)
        external
        payable
        onlySender
        nonReentrant
    {
        require(amount > 0);
        require(amount <= maxPerTx);
        require((totalSupply() + amount) <= collectionSize - reservedSize);
        require(mintPrice * amount <= msg.value);
 
        if (whitelistRequired) {
            require(whitelistSaleActive);

            uint256 additional;
            uint256 surplus;

     for (uint256 i = 0; i < _borps.length; i++) {
                if(_borps[i]>10000){ //borpi

             if(!borpiUsed[_borps[i]-10000] && (NFTBalance(msg.sender, borpiAddress, _borps[i]-10000) == true)){
                 borpiUsed[_borps[i]-10000]=true;
                 additional++;
             }             
         
            }else{ //borpacasso    

             if(!borpacassoUsed[_borps[i]] && (NFTBalance(msg.sender, borpacassoAddress, _borps[i]) == true)){
                 borpacassoUsed[_borps[i]]=true;   
                 additional++;
                 } 
            }
            if(additional==amount){break;}
            }

            if (additional < amount) {
                surplus = amount - additional;

                require(surplus <= whitelist[msg.sender]);
                whitelist[msg.sender] -= surplus;
            }
        } else {
            require(regularSaleActive);
        }
        _safeMint(msg.sender, amount);
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 COUNTERFEITER
    function counterfeiter(
        uint256 borpacassoID,
        uint256 borpiID,
        uint256 nftIndex,
        uint256 mintpass
    ) external payable onlySender nonReentrant {
        require((totalSupply() + 1) <= collectionSize - reservedSize);
        require(mintPrice <= msg.value);

        //check whitelist
        if (whitelistRequired) {
            require(whitelistSaleActive);
            if (mintpass > 10000) {
                require(
                    NFTBalance(msg.sender, borpiAddress, mintpass - 10000) ==
                        true
                );
                require(borpiUsed[mintpass - 10000] == false);
                borpiUsed[mintpass - 10000] = true;
            } else if (mintpass > 0) {
                require(
                    NFTBalance(msg.sender, borpacassoAddress, mintpass) == true
                );
                require(borpacassoUsed[mintpass] == false);
                borpacassoUsed[mintpass] = true;
            } else {
                require(whitelist[msg.sender] >= 1);
                whitelist[msg.sender] -= 1;
            }
        } else {
            require(regularSaleActive);
        }

        //traits check
        if (borpacassoID > 0) {
            require(
                NFTBalance(msg.sender, borpacassoAddress, borpacassoID) == true
            );
        }
        if (borpiID > 0) {
            require(NFTBalance(msg.sender, borpiAddress, borpiID) == true);
        }
        if (nftIndex > 0) {
            require(NFTOwnAny(msg.sender, nftAddresses[nftIndex]) == true);
        }

        traits[totalSupply()] = [borpacassoID, borpiID, nftIndex];
        _safeMint(msg.sender, 1);
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 WITHDRAW
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 cut = balance / 2;
        payable(borpFanOne).transfer(cut);
        payable(borpFanTwo).transfer(cut);
    }

    //🐸🐸🐸🐸🐸🐸🐸🐸 METADATA STUFF
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function getTraits(uint256 id) public view returns (uint256[3] memory) {
        return [traits[id][0], traits[id][1], traits[id][2]];
    }
}