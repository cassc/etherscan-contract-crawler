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
Web: ethlizards.io
Underground Lizard Lounge Discord: https://discord.com/invite/ethlizards
Developer: Sp1cySauce - Discord: SpicySauce#1615 - Twitter: @SaucyCrypto
Props: Chance - for Optimizations
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721Enumerable.sol";

contract Lizards is ERC721Enumerable, Ownable {
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    string public foundersURI;
    string public auctionURI;

    address public proxyRegistryAddress;
    address public bettyFromAccounting;

    bytes32 public OGMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    mapping(address => bool) public projectProxy;

    mapping(address => uint256) public OGMinted;
    mapping(address => uint256) public WLMinted;

    uint256 public maxLizardSupply = 5051; //Actial Max Supply is 5050
    uint256 public constant maxLizardPerMint = 11; //Actual Max Mint Amount is 10
    uint256 public constant cost = 0.06 ether;
    uint256 public constant auctionReservations = 5;
    uint256 public constant teamReservations = 100;
    uint256 public constant foundersReservations = 10;

    bool public revealed = false;
    bool public onlyOGMints = false;
    bool public onlyWLMints = false;
    bool public publicMint = false;

    constructor(
        string memory _BaseURI,
        string memory _NotRevealedUri,
        string memory _FoundersURI,
        string memory _AuctionURI,
        address _proxyRegistryAddress,
        address _bettyFromAccounting
    ) ERC721("Ethlizards", "LIZARD") {
        setBaseURI(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
        setFoundersURI(_FoundersURI);
        setAuctionURI(_AuctionURI);
        proxyRegistryAddress = _proxyRegistryAddress;
        bettyFromAccounting = _bettyFromAccounting;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function _foundersURI() internal view virtual returns (string memory) {
        return foundersURI;
    }

    function _auctionURI() internal view virtual returns (string memory) {
        return auctionURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setFoundersURI(string memory _newFoundersURI) public onlyOwner {
        foundersURI = _newFoundersURI;
    }

    function setAuctionURI(string memory _newAuctionURI) public onlyOwner {
        auctionURI = _newAuctionURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        if (tokenId < foundersReservations) {
            string memory currentfoundersURI = _foundersURI();
            return
                bytes(currentfoundersURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentfoundersURI,
                            Strings.toString(tokenId),
                            baseExtension
                        )
                    )
                    : "";
        }

        if (
            tokenId >= foundersReservations &&
            tokenId < (foundersReservations + auctionReservations)
        ) {
            string memory currentAuctionURI = _auctionURI();
            return
                bytes(currentAuctionURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentAuctionURI,
                            Strings.toString(tokenId),
                            baseExtension
                        )
                    )
                    : "";
        }

        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setOGMerkleRoot(bytes32 _OGMerkleRoot) external onlyOwner {
        OGMerkleRoot = _OGMerkleRoot;
    }

    function setOnlyOGMints(bool _state) public onlyOwner {
        onlyOGMints = _state;
    }

    function setOnlyWLMints(bool _state) public onlyOwner {
        onlyWLMints = _state;
    }

    function setPublicSale(bool _state) public onlyOwner {
        publicMint = _state;
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxLizards(uint256 _maxLizardAmount) public onlyOwner {
        maxLizardSupply = _maxLizardAmount;
    }

    function _OGVerify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, OGMerkleRoot, leaf);
    }

    function OGmint(
        uint256 _mintAmount,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        bytes32 OGLeaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(_OGVerify(OGLeaf, proof), "Invalid Proof Supplied.");
        require(
            OGMinted[msg.sender] + _mintAmount <= allowance,
            "Exceeds OG mint allowance"
        );
        require(onlyOGMints, "OG minting must be active to mint");
        OGMinted[msg.sender] += _mintAmount;
        uint256 totalSupply = _owners.length;
        for (uint256 i; i < _mintAmount; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function _WlVerify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function WLmint(
        uint256 _mintAmount,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        bytes32 WLLeaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(_WlVerify(WLLeaf, proof), "Invalid Proof Supplied.");
        require(
            WLMinted[msg.sender] + _mintAmount <= allowance,
            "Exceeds white list mint Allowance"
        );
        require(onlyWLMints, "White list minting must be active to mint");
        require(msg.value == cost * _mintAmount, "Wrong amount of Ether sent");
        WLMinted[msg.sender] += _mintAmount;
        uint256 totalSupply = _owners.length;
        for (uint256 i; i < _mintAmount; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 totalSupply = _owners.length;
        require(publicMint, "Public minting is not currently available"); //ensure Public Mint is on
        require(
            _mintAmount < maxLizardPerMint,
            "max mint amount per mint exceeded"
        );
        require(
            totalSupply + _mintAmount < maxLizardSupply,
            "Sorry, this would exceed maximum Lizard mints"
        ); //require that the max number has not been exceeded
        require(msg.value == cost * _mintAmount, "Wrong amount of Ether sent");

        for (uint256 i; i < _mintAmount; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function collectFoundersReserves() external onlyOwner {
        require(_owners.length == 0, "Reserves already taken.");
        for (uint256 i; i < foundersReservations; i++) {
            _mint(_msgSender(), i);
        }
    }

    function collectAuctionReserves() external onlyOwner {
        require(
            _owners.length == foundersReservations,
            "Reserves already taken."
        );
        uint256 totalSupply = _owners.length;
        for (uint256 i; i < auctionReservations; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function collectTeamReserves() external onlyOwner {
        require(
            _owners.length == foundersReservations + auctionReservations,
            "Reserves already taken."
        );
        uint256 totalSupply = _owners.length;
        for (uint256 i; i < teamReservations; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function withdraw() public {
        (bool success, ) = bettyFromAccounting.call{
            value: address(this).balance
        }("");
        require(success, "Failed to send to Betty.");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
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

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}