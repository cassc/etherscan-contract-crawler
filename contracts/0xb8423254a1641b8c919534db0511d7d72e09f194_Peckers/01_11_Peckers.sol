// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
/*
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::=+++++++++++++++++::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::-====*@@@@@@@@@@@@@@@@@=====:::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::*@@@@@%%%%%%%%%%%%%%%%%@@@@@:::::::::::::::::::::::::::::::::::
::::::::::::::::::::::[email protected]@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%@@*::::::::::::::::::::::::::::::::
::::::::::::::::::::##%@@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@@@@%##::::::::::::::::::::::::::::::
:::::::::::::::::[email protected]@@@@%%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@*+=:::::::::::::::::::::::::::
:::::::::::::::::[email protected]@@@@%%%%%%%@@@@@@@@@@%%@@@%%@@@%%@@@%%@@@@@#==:::::::::::::::::::::::::
:::::::::::::::::[email protected]@@@@%%%%%%%@@@@@@%@@@%%@@@%%%@@%%%@@%%%@@@%@@@:::::::::::::::::::::::::
:::::::::::::::@@@@@@@@@@@%@@@@@@@@@%@@@%%@@@%%@@@%%@@@%%@@@%%%@@:::::::::::::::::::::::::
:::::::::::::::@@@@@@@@@@@@@@@@@@@@@%@@@%%@@@@@@@@@@@@@@@@@@%%@@@:::::::::::::::::::::::::
:::::::::::::::@@@@@@@@@@@@@@@%%@@@@@@@@@@%%%%%%%%%%%##%%%@@@@#**:::::::::::::::::::::::::
:::::::::::::::##%@@@@@@@@@@@@@@@@@@@@@@##*++#######*++##%@@@@*:::::::::::::::::::::::::::
:::::::::::::::::[email protected]@@@@@@@@@@@@@@@@@@%##  .::#############%%%%+:::::::::::::::::::::::::::
:::::::::::::::::[email protected]@@@@@@@@@@@@@%####-       ::=############%%+:::::::::::::::::::::::::::
:::::::::::::::::[email protected]@@@@@@@@@#######-         :--:...:--+##%%+:::::::::::::::::::::::::::
::::::::::::::::::::**#@@@@@@@#######-         .::     ..:==%%+:::::::::::::::::::::::::::
::::::::::::::::::::::+%%@@@@@%%#####-     ....:::   .......%%+:::::::::::::::::::::::::::
:::::::::::::::::::::::::@@@%%%%#####-    -****=::  :****-  %%+:::::::::::::::::::::::::::
:::::::::::::::::::::::::::+%%%%%%%##-    -**%%+::  :**%%=  %%+::::+%%%%+:::::::::::::::::
:::::::::::::::::::::::::::+%%%%%%%##-    -**%%*==--=**%%=  %%#####*==%%+:::::::::::::::::
:::::::::::::::::::::::::::+%%%%%%%*+=::::-++**+====+++**=::*******+==%%+:::::::::::::::::
:::::::::::::::::::::::::::+%%%%%%%+===============================+####+:::::::::::::::::
:::::::::::::::::::::::::::+%%%%#**=========================-----**#%%-:::::::::::::::::::
:::::::::::::::::::::::::::+%%%%#**==*%%%%*===================+**%%*::::::::::::::::::::::
:::::::::::::::::::::::::::-==%%#****+++%%#*******************#%%==-::::::::::::::::::::::
::::::::::::::::::::::::::::::++*##***++++*###################*++:::::::::::::::::::::::::
::::::::::::::::::::::::::::::::=#######::=#######%%%%%%%%####+:::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::%%%%%++=--::-++*****%%+::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::%%#**==*%%%%%%%:::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::=*******%%#**::+%%%%%%%**=::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::+%%###**%%%##--+%%###**%%+::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::=**##*++%%%%%==*%%*******=::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::#%######%%--+%%++*%%:::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::##########++*##===++*######+::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::*****#####++*##***##*****##*++*******=:::::::::::::::::::::::::::
::::::::::::::::::::::-++##########++*############**+==++******++:::::::::::::::::::::::::
::::::::::::::::::::::+%%##******##**********##***++===+++++++*##---::::::::::::::::::::::
::::::::::::::::::::::+%%##+====+##+++++==+++##*+++++++--=++++=--%%+::::::::::::::::::::::
*/
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { DefaultOperatorFilterer } from './DefaultOperatorFilterer.sol';


contract Peckers is ERC721A, Ownable, ReentrancyGuard, Pausable, DefaultOperatorFilterer{

    // uint256 mint variables
    uint256 public maxSupply = 7777;
    uint256 public cap1 = 3333;
    uint256 public mintPrice = 0.0033 ether;
    uint256 public maxMintPerWallet = 10;

    //base uri, base extension
    string public baseExtension = ".json";
    string public baseURI;

    // booleans for if mint is enabled
    bool public mintEnabled = false;


    constructor (
        string memory _initBaseURI
        ) ERC721A("PECKERS", "PECK") {
            setBaseURI(_initBaseURI);
    }

    function devMint(address[] calldata _address, uint256 _amount) external onlyOwner nonReentrant {

        require(totalSupply() + _amount <= maxSupply, "Error: max supply reached");

        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _amount);
        }
    }

    function mint(uint256 _quantity) external payable whenNotPaused nonReentrant {
        if (totalSupply() <= cap1) { // EXECUTE LOGIC BELOW IF SUPPLY IS LOWER THEN CAP1 VARIABLE
            // RETRIEVE AMOUNT USER HAS PREVIOUSLY MINTED
            uint256 previous = _getAux(_msgSender());           
            // MINT NEEDS TO BE ENABLED
            require(mintEnabled, 'PeckError: Sale is NOT live');
            // NO CONTRACT MINTING
            require(tx.origin == msg.sender, 'PeckError: No contracts');
            // SETTING MAX SUPPLY CAP
            require(totalSupply() + _quantity <= maxSupply, "PeckError: Max supply reached");
            // ENFORCING MAX MINTS PER WALLET
            require(previous + _quantity <= maxMintPerWallet, "PeckError: Cannot mint more than 10 Peckers per wallet");
            // CHECKOUT LOGIC FOR CALCULATING TOTAL PRICE
            uint256 freeCount = previous >= 3
            ? 0
            : 3 - previous;
            uint256 paidCount = _quantity > freeCount
            ? _quantity - freeCount
            : 0;
            // SETTING PRICE REQUIRED TO SUCCESSFULLY MINT
            require(msg.value >= mintPrice * paidCount, "Not enough ether sent");
            _setAux(_msgSender(), uint64(previous += _quantity)); // SET USER MINTS
            _safeMint(msg.sender, _quantity); // MINT
        } else { // EXECUTE LOGIC BELOW IF SUPPLY IS HIGHER THEN CAP1 VARIABLE
                // RETRIEVE AMOUNT USER HAS PREVIOUSLY MINTED
                uint256 previous = _getAux(_msgSender());
                // NO CONTRACT MINTING
                require(tx.origin == msg.sender, 'PeckError: No contracts');
                // SETTING MAX SUPPLY CAP
                require(totalSupply() + _quantity <= maxSupply, "PeckError: Max supply reached");
                // ENFORCING MAX MINTS PER WALLET
                require(previous + _quantity <= maxMintPerWallet, "PeckError: Cannot mint more than 10 Peckers per wallet");
                // CHECKOUT LOGIC FOR CALCULATING TOTAL PRICE
                uint256 freeCount = previous >= 1
                ? 0
                : 1 - previous;
                uint256 paidCount = _quantity > freeCount
                ? _quantity - freeCount
                : 0;
                // SETTING PRICE REQUIRED TO SUCCESSFULLY MINT
                require(msg.value >= mintPrice * paidCount, "Not enough ether sent");
                _setAux(_msgSender(), uint64(previous += _quantity)); // SET USER MINTS
                _safeMint(msg.sender, _quantity); // MINT
            }
    }


    // =============================================================
    //                Metadata / URI / IPFS
    // =============================================================
    // returns the baseuri of collection, private
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // override _statTokenId() from erc721a to start tokenId at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // return tokenUri given the tokenId
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
        
    }

    // =============================================================
    //                Opensea Operator Filter Registry
    // =============================================================
        function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
            super.setApprovalForAll(operator, approved);
        }

        function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
        }

        function transferFrom(
            address from,
            address to,
            uint256 tokenId
        ) public payable override onlyAllowedOperator(from) {
            super.transferFrom(from, to, tokenId);
        }

        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
        ) public payable override onlyAllowedOperator(from) {
            super.safeTransferFrom(from, to, tokenId);
        }

        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes memory data
        ) public payable override onlyAllowedOperator(from) {
            super.safeTransferFrom(from, to, tokenId, data);
        }

        function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
        {
            return super.supportsInterface(interfaceId);
        }

    // =============================================================
    //                         FUNCTIONS
    // =============================================================
       function numberMinted(address wallet) external view returns (uint256) {
        return _getAux(wallet);
    }

    function toggleMint() external onlyOwner nonReentrant{
        mintEnabled = !mintEnabled;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner nonReentrant{
    mintPrice = _mintPrice;
    }

   function pause() public onlyOwner nonReentrant{ 
        _pause();
    }

    function unpause() public onlyOwner nonReentrant{
        _unpause();
    }

    function setBaseURI(string memory _newURI) public onlyOwner nonReentrant{
        baseURI = _newURI;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner nonReentrant {
        maxSupply = _maxSupply;
    }

    // =============================================================
    //                     WITHDRAWL TO OWNER
    // =============================================================
    function withdraw() external onlyOwner nonReentrant {
    
        payable(owner()).transfer(address(this).balance);
    }


}