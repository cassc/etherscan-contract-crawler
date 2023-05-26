// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// *********************************:::::::::::::::::::::::::::::::::...............:::::::::::::::::**********************:::::::::::
// *********************************:::::::::::::::::::::::::::::::::...............:::::::::::::::::**********************:::::::::::
// *********************************:::::::::::::::::::::::::::::::::............::::::::::::::::::::**********************:::::::::::
// ******************************::::::::::::::::::::::::::::::::.::...........:::::::::::::::::**********************:::::::::::.....
// *****************************::::::::::::::::::::::::::::::::::::...........:::::::::::::::::**********************::::::::::::::::
// ***************************:::::::::::::::::::::::::::::::::............::.:::::::::::::::::**********************::::::::::::.....
// ***************************:::::::::::::::::::::::::::::::::...........:::::::::::::::::**********************:::::::::::.::.......
// ***************************::::::::::::::::::::::::::::.................::::::::::::::::**********************:::::::::::.:........
// **********************:::::::::::::::::::::::::::F$$$$$$$$$I......:::::I$$$$$$$$$I::***********************:*:::::::::::...........
// *********************::::::::::::::::::::::::::::IMMMMNNMMM$......::.::$MMNNNNMMM$::*********************:*:::::::::::::......:.:::
// *****************:***::::::::::::::::::::::::::::$MMMNNNNNM$:::::::::::$MMNNNNNMM$**********************::::::::::::.::.......:::::
// ****************:::::::::::::::::::::::::::*MMMMMMMMNNNNNNMMMMMMMMMMMMMMMNNNNNNMMMMMMMMF***************:::::::::::...........::::::
// ****************:::::::::::::::::::::::::::*MMMMMMMMNNNNNNMMMMMMNMMMMMMMMNNNNNNNMMMMMMMF***************:::::::::::...........::::::
// ***************::::::::::::::::::::::::::::*MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMF**********:::::::::::::.........:::::::::::
// ***********::::::::::::::::::::::::::::::::*MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMF**********:::::::::::...........:::::::::::
// ***********::::::::::::::::::::::::::::::::*MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNMF**********:::::::::::...........:::::::::::
// **********:::::::::::::::::::::::::::::::..*MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMF*****:::::::::::...........::::::::::::::::
// ******::::::::::::::::::::::::::::::::.....*MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMF*****:::::::::::..........:::::::::::::::::
// ******::::::::::::::::::::::::::::::::::::.*MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMF*****:::::::::::......:::::::::::::::::::::
// *****:::::::::::*$$$$F::::::::::::..:.I$$$$MMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMM$$$$I::::::..:.......F$$$$*:::::::::::*****
// ::::::::::::::::FMMMMI:::::::::::.....$MMMMNMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMNNMMMM$::::::.::.......VMMMMF:::::::::::*****
// ::::::::::::::::FMMMM$****************$MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMM$****************$MMMNF::::::::::******
// ::::::::::::::::FMMMMMMMMMMMMMNMMMNMMMMNMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMNNNNNNNNNMMMMMMMMMMF:::::***********
// ::::::::::::::::FMMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMF:::::***********
// ::::::::::::::::*****FMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMIFFFF*:::::***********
// :::::::::::::::::::::*MMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMM*:::::****************
// :::::::::::::::::::::*$MMMMMMMMMMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMMMMMMMMM$*:::::****************
// ::::::::::::::::::::::::::::::::::::::$MMNNNNNNNNNNNN - EXPANSION PUNKS - NNNNNNNNNNNNNNNMMM$:::::::::::***:*::::******************
// :::::::::::::::::::::............::::.$MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN$:.::.::::::::::::**:******************
// :::::::::::::::::::::............::::.$N    A community-led expansion to the CryptoPunks   M$:::::::::::::::::*********************
// :::::::::::::::::...........::::::::::$M    phenomena that empowers everyone to feel       M$::::::::::::::::**********************
// :::::::::::::::::...........:...::::::$M    welcome, valued and represented in the         M$::::::::::::::::**********************
// ::::::::::::::::...........::::::*****$M    emerging metaverse. Honoring the ethos of      M$:::::::::::**:************************
// :::::::::::...............::::::*MNMMMNM    the original collection's design philosophies  M$:::::::::::***************************
// :::::::::::...............::::::*MNNNNNN    and trait principles, ExpansionPunks are fully M$:::::::::::***************************
// ::::::::..............::::::::::*MMNMNNN    unique and diverse additions to the Punkverse. M$*::::*********************************
// ::::::...............:::::::::::*MMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$*::::*********************************
// ::::::...............:::::::::::*MMMMNNNNNNNNNNNNN   MADE WITH <3 BY JP & FU   NNNNNNNNNNNMN$*::::*********************************
// :::::...........::::::::::::::::*MMNMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMN$**************************************
// :::::...........::::::::::::::::*MMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$**************************************
// ............:::.::::::::::::::::*IIIII$MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$**************************************
// ...........::::::::::::::::***********$MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$**************************************
// ...........::::::::::::::::***********$MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMM$**************************************
// .......:..:::::::::::::::::***********$MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$**************************************
// .....:::::::::::::::::****************$MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNM$***********FF*F******************:::::
// .....:::::::::::::::::****************$MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMM$***********FF*F******************:::::
// .....::::::::::::*:*:*****************$MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$F****************************:**::::::
// :::::::::::::::::**:******************$MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$F*****FF********************::::::::::
// :::::::::::::::::*********************$MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMM$***************************:::::::::::
// ::::::::::::::::**********************$MMMNNNNMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMM$***********************::*::::::::::::
// ::::::::::::*:::**********************$MMMMMNNMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMM$************************:*::::::::::::
// :::::::::::**********************:::::*FFFFIMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMM$IIIII**********************::::::::::::::::
// :::::::::::**********************::::::::::*MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMI**************************:::::::::::::::::
// :::::::::::**********************::::::::::*MMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMI**************************:::::::::::::::::
// :::::***********************:::::::::::....*MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMM$FFFFF**********************:::::::::::::::::.....
// :::::**********************::::::::::::....*MMMNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMM$***************************:::::::::::::::::.....
// :::::**********************::::::::::::....*MNMNNNNNNNNNNNNNNNNNNNNNNNNNNNMMM$$$$$***************************:::::::::::::::::.....
// **********************:::::::::::.::.......*MNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMF***************************:::::::::::::::::::::......
// **********************::::::::::::::.......*MNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMF***************************:::::::::::::::::::::......
// *********************::::::::::::..........*MNNNNNNNNNNNNNNNNNNNNNNNNMM$IIIIF**************************::::::::::::::::::..........
// *****************:::::::::::::::.......::::*MMMNNNNNNNNNNNNNNNNNNNNNNMMF***************************:::::::::::::::::::::......:::::
// *****************:::::::::::::::.......::::*MMMNNNNNNNNNNNNNNNNNNNNNNMMF**************************:::::::::::::::::::::::.....:::::
// ****************:::::::::::...........:::::*MMMNNNNNNNNNNNNNNNNNNNNNNMMF**************************:::::::::::::::::::::::....::::::
// **************:*:::::::::::...........:::::*MMMNNNNNNNNNNNNNNNNNNNNNNMMF**********************:::::::::::::::::::::::::::::::::::::
// **************:*:::::::::::...........:::::*MMMNNNNNNNNNNNNNNNNNNNNNNMMF**********************:::::::::::::::::::::::::::::::::::::


contract ExpansionPunks is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ----- Token config -----
    // Total number of ExpansionPunks that can be minted
    uint256 public constant maxSupply = 10000;
    // Number of ExpansionPunks reserved for promotion & giveaways
    uint256 public totalReserved = 100;
    // IPFS hash of the 100x100 grid of the ExpansionPunks
    string public EP_PROVENANCE_SHA256 = "2BAFBF1C1DEC1349579B033BAAFBFF55ABD9230EE94F6E04BEB9DE4D023333E7";
    string public EP_PROVENANCE_IPFS = "bafybeigqmo7mlti7sevdy5x33zaohvqbshrlvwavlwp3seknt5v4ar7x5q";
    
    // Root of the IPFS metadata store
    string public baseURI = "";
    // Current number of tokens
    uint256 public numTokens = 0;
    // remaining ExpansionPunks in the reserve
    uint256 private _reserved;

    // ----- Sale config -----
    // Price for a single token
    uint256 private _price = 0.06 ether;
    // Can you mint tokens already
    bool private _saleStarted;

    // ----- Owner config -----
    address public jp = 0x3Cd1676e8e0511aa96495c8eB24879d584dc3fdB;
    address public fu = 0x277ad5d56cB83DBfe5926232495888ABc0710e2F;
    address public dao = 0x6Df748fD1d9154FFAEa6F2F59d369cCaCc1c9F2c;

    // Mapping which token we already handed out
    uint256[maxSupply] private indices;

    // Constructor. We set the symbol and name and start with sa
    constructor(
    ) ERC721("ExpansionPunks", "xPUNK") {
        _saleStarted = false;
        _reserved = totalReserved;
    }

    receive() external payable {}

    // ----- Modifiers config -----
    // restrict to only allow when we have a running sale
    modifier saleIsOpen() {
        require(_saleStarted == true, "Sale not started yet");
        _;
    }

    // restrict to onyl accept requests from one either deployer, jp or fu
    modifier onlyAdmin() {
        require(
            _msgSender() == owner() || _msgSender() == jp || _msgSender() == fu,
            "Ownable: caller is not admin"
        );
        _;
    }

    // ----- ERC721 functions -----
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ----- Getter functions -----
    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getReservedLeft() public view returns (uint256) {
        return _reserved;
    }

    function getSaleStarted() public view returns (bool) {
        return _saleStarted;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ----- Setter functions -----
    // These functions allow us to change values after contract deployment

    // Way to change the baseUri, this is usefull if we ever need to switch the IPFS gateway for example
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    // ----- Minting functions -----

    /// @notice Select a random number without modulo bias using a random seed and upper bound
    /// @param _entropy The seed for randomness
    /// @param _upperBound The upper bound of the desired number
    /// @return A random number less than the _upperBound
    function uniform(uint256 _entropy, uint256 _upperBound)
        internal
        pure
        returns (uint256)
    {
        require(_upperBound > 0, "UpperBound needs to be >0");
        uint256 negation = _upperBound & (~_upperBound + 1);
        uint256 min = negation % _upperBound;
        uint256 randomNr = _entropy;
        while (true) {
            if (randomNr >= min) {
                break;
            }
            randomNr = uint256(keccak256(abi.encodePacked(randomNr)));
        }
        return randomNr % _upperBound;
    }

    /// @notice Generates a pseudo random number based on arguments with decent entropy
    /// @param max The maximum value we want to receive
    /// @return _randomNumber A random number less than the max
    function random(uint256 max) internal view returns (uint256 _randomNumber) {
        uint256 randomness = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    block.difficulty
                )
            )
        );
        _randomNumber = uniform(randomness, max);
        return _randomNumber;
    }

    /// @notice Generates a pseudo random index of our tokens that has not been used so far
    /// @return A random index between 10000 and 19999
    function randomIndex() internal returns (uint256) {
        // id of the gerneated token
        uint256 tokenId = 0;
        //  number of tokens left to create
        uint256 totalSize = maxSupply - numTokens;
        // generate a random index
        uint256 index = random(totalSize);
        // if we haven't handed out a token with nr index we that now

        uint256 tokenAtPlace = indices[index];

        // if we havent stored a replacement token...
        if (tokenAtPlace == 0) {
            //... we just return the current index
            tokenId = index;
        } else {
            // else we take the replace we stored with logic below
            tokenId = tokenAtPlace;
        }

        // get the highest token id we havent handed out
        uint256 lastTokenAvailable = indices[totalSize - 1];
        // we need to store a replacement token for the next time we roll the same index
        // if the last token is still unused...
        if (lastTokenAvailable == 0) {
            // ... we store the last token as index
            indices[index] = totalSize - 1;
        } else {
            // ... we store the token that was stored for the last token
            indices[index] = lastTokenAvailable;
        }

        // We start our tokens at 10000
        return tokenId + (10000);
    }

    /// @notice Select a number of tokens and send them to a receiver
    /// @param _number How many tokens to mint
    /// @param _receiver Address to mint the tokens to
    function _internalMint(uint256 _number, address _receiver)
        internal
    {
        for (uint256 i; i < _number; i++) {
            uint256 tokenID = randomIndex();
            numTokens = numTokens + 1;
            _safeMint(_receiver, tokenID);
        }
    }

    /// @notice Mint a number of tokens and send them to a receiver
    /// @param _number How many tokens to mint
    function mint(uint256 _number)
        external
        payable
        nonReentrant
        saleIsOpen
    {
        uint256 supply = uint256(totalSupply());
        require(
            supply + _number <= maxSupply - _reserved,
            "Not enough ExpansionPunks left."
        );
        require(
            _number < 21,
            "You cannot mint more than 20 ExpansionPunks at once!"
        );
        require(_number * _price == msg.value, "Inconsistent amount sent!");
        _internalMint(_number, msg.sender);
    }

    // ----- Sale functions -----

    /// @notice Flip the sale status
    function flipSaleStarted() external onlyAdmin {
        _saleStarted = !_saleStarted;
    }

    // ----- Helper functions -----
    /// @notice Get all token ids belonging to an address
    /// @param _owner Wallet to find tokens of
    /// @return  Array of the owned token ids
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /// @notice Claim a number of tokens from the reserve for free
    /// @param _number How many tokens to mint
    /// @param _receiver Address to mint the tokens to
    function claimReserved(uint256 _number, address _receiver)
        external
        onlyAdmin
    {
        require(_number <= _reserved, "That would exceed the max reserved.");
        _internalMint(_number, _receiver);
        _reserved -= _number;
    }

    /// @notice his will take the eth on the contract and split it based on the logif below and send it out.  We funnel 1/3 for each dev and 1/3 into the ExpansionPunkDAO
    function withdraw() public onlyAdmin {
        uint256 _balance = address(this).balance;
        uint256 _split = _balance.mul(33).div(100);
        require(payable(jp).send(_split));
        require(payable(fu).send(_split));
        require(payable(dao).send(_balance.sub(_split * 2)));
    }
}