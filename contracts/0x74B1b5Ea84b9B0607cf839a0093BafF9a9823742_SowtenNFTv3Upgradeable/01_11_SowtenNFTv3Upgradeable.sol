//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "contracts/token/ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "contracts/utils/Strings.sol";

// inspired by Azuki, TheStripesNFT
// https://github.com/chiru-labs/ERC721A-Upgradeable
// https://github.com/The-Stripes-NFT/the-stripes-nft-contract
contract SowtenNFTv3Upgradeable is ERC721AUpgradeable, OwnableUpgradeable {
    using Strings for uint256;
    
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 50;  // enable num to mint(MAX)
    uint256 public salePeriod = 1;      // 1:PREMINT, 2:WL1, 3:WL2, ..., 0:public
    bool public paused = false;
    /* mint num on salePeriod */
    mapping(address => uint[10]) public whitelisted;    // enable num to mint per whitelisted/salePeriod (0: unable)
    mapping(address => uint[10]) public mintAmount;     // mint count per whitelisted/salePeriod
    /* presale price on salePeriod */
    mapping(uint => uint256) public price;      // uint: 1:presale, 2:2nd presale, ..., 0:public
    mapping(uint => uint256) public totalSupplyOnPeriod;      // uint: 1:presale, 2:2nd presale, ..., 0:public
    mapping(uint => uint256) public maxSupplyOnPeriod;      // uint: 1:presale, 2:2nd presale, ..., 0:public
    mapping(uint => bool) public anyoneCanMint;  // public on mint site(anyone can mint).

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _publicPrice
    ) initializerERC721A initializer public {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        setBaseURI(_initBaseURI);
        price[0] = _publicPrice;
        price[1] = 0.05 ether;  // PREMINT(salePeriod = 1)
        price[2] = 0.055 ether; // WL1
        price[3] = 0.06 ether;  // WL2
        maxSupplyOnPeriod[0] = maxSupply;
        maxSupplyOnPeriod[1] = 200; // PREMINT(salePeriod = 1)
        maxSupplyOnPeriod[2] = 400; // WL1
        maxSupplyOnPeriod[3] = 600; // WL2
        anyoneCanMint[0] = true;
        anyoneCanMint[1] = false;
        anyoneCanMint[2] = false;
        anyoneCanMint[3] = false;
        mintOnPeriod(msg.sender, 1, 0);  // salePeriod = 0
    }

    /* internal */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* public */
    function mint(address _to, uint256 _mintAmount) public payable {
        mintOnPeriod(_to, _mintAmount, 0);
    }

    function mintOnPeriod(address _to, uint256 _mintAmount, uint256 _salePeriod) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(_mintAmount <= maxMintAmount, "The mint num has been exceeded.(Total)");
            require(totalSupplyOnPeriod[_salePeriod] + _mintAmount <= maxSupplyOnPeriod[_salePeriod], "The mint num has been exceeded.(On Period)");
            require(msg.value >= price[_salePeriod] * _mintAmount, "The price is incorrect."); // price
            if((_salePeriod != 0) && (anyoneCanMint[_salePeriod] == false) && (whitelisted[msg.sender][_salePeriod] == 0)) {
                revert("Not permitted to mint during this sales period.");
            }
            if((_salePeriod != 0) && (_mintAmount + mintAmount[msg.sender][_salePeriod] > whitelisted[msg.sender][_salePeriod])) {
                revert("Exceeded the number of mints permitted for this sales period.");
            }
        }

        // Mint Method (ERC721A)
        _mint(_to, _mintAmount);
        mintAmount[_to][_salePeriod] = mintAmount[_to][_salePeriod] + _mintAmount;
        totalSupplyOnPeriod[_salePeriod] = totalSupplyOnPeriod[_salePeriod] + _mintAmount;
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

    function getPriceOnPeriod(uint256 _salePeriod) public view returns(uint256){
        return price[_salePeriod];
    }

    function getWhitelistUserOnPeriod(address _user, uint256 _salePeriod) public view returns(uint256) {
        return whitelisted[_user][_salePeriod];
    }

    function getMintAmountOnPeriod(address _user, uint256 _salePeriod) public view returns(uint256) {
        return mintAmount[_user][_salePeriod];
    }

    function getTotalSupplyOnPeriod(uint256 _salePeriod) public view returns(uint256) {
        return totalSupplyOnPeriod[_salePeriod];
    }

    function getMaxSupplyOnPeriod(uint256 _salePeriod) public view returns(uint256) {
        return maxSupplyOnPeriod[_salePeriod];
    }

    function getAnyoneCanMint(uint256 _salePeriod) public view returns(bool) {
        return anyoneCanMint[_salePeriod];
    }

    /* only owner */
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

    function setSalePeriod(uint256 _salePeriod) public onlyOwner {
        salePeriod = _salePeriod;
    }

    function setPriceOnPeriod(uint256 _salePeriod, uint256 _price) public onlyOwner {
        price[_salePeriod] = _price;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMaxSupplyOnPeriod(uint256 _salePeriod, uint256 _maxSupplyOnPeriod) public onlyOwner {
        maxSupplyOnPeriod[_salePeriod] = _maxSupplyOnPeriod;
    }

    function setAnyoneCanMint(uint256 _salePeriod, bool _anyoneCanMint) public onlyOwner {
        anyoneCanMint[_salePeriod] = _anyoneCanMint;
    }

    function addWhitelistUserOnPeriod(address _user, uint256 _mintNum, uint256 _salePeriod) public onlyOwner {
        whitelisted[_user][_salePeriod] = _mintNum;
    }

    function addWhitelistUserOnPeriodBulk(address[] memory _users, uint256 _mintNum, uint256 _salePeriod) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]][_salePeriod] = _mintNum;
        }
    }

    function removeWhitelistUserOnPeriod(address _user, uint256 _salePeriod) public onlyOwner {
        whitelisted[_user][_salePeriod] = 0;
    }

    function airdropNfts(address[] calldata wAddresses) public onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
            _mint(wAddresses[i], 1);
        }
        totalSupplyOnPeriod[0] = totalSupplyOnPeriod[0] + wAddresses.length;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}