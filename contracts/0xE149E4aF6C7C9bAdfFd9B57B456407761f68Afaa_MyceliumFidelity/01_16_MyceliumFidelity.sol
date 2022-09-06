// SPDC-License-Identifier: MIT
pragma solidity ^0.8.12;

//::;cc:cc::ccc:clccccccccc:;,;ccc:,,:cclcclc:clcllcccc::;;:ccccccccllcc:::,.,:::ccccccclccllcclclcccccccccccccccccll:,;,.
//c:;cc::c::cclcccccccccccccc;;:ccc;,:ccclcllcclcclcccc::,,:lllccccccc:::cc:.':c:c::cccccccllcclcllccccccccclcccccccc,,;,.
//:c:cc::c::cclcccc:ccccccccc;;:ccc:,;:ccccccccllccllccc:;''::::::,,;:;;ccc:'.;;;:cccccccccccccccccccccccccclccclcc:,',;'.
//:c::l:;c:::clc::::ccccccccc:,;:cc:,';:ccccccccllcllccc::,.''..';,,;::cccc;..';;;::cc::cccccccc::cccclcclllllccccc;..',..
//;cc:cc::c::ccc:::;;:c:cc:cc:;;::cc,';ccccccc:cllcclccccc:'','',ccc:cccccc;'';:::::::;;;;;;:c:;;:ccccllcllcclcc::,...,,..
//::c:cc::c::cccc:cc;;;:ccc:::::;,;:;';::cc::cc:cccclcccc:;'.',;:ccccclccc:'';:ccccc::;,,;::::;;;;:ccccccclcc:;,,,'',;::'.
//;:c::c:;cc::ccc:cccc:;::::cc:c:;,;:;,,,;:;;:;,;:::::ccc:,',,;:cccc::cccc,';cccccc:;,,;:ccc:,';c::cccccccc:;;;;;'.',:c:' 
//;:c:;:::::::cccccccccc:;,,::::c:,:c:;,',;,',,:cc::;;,,;,',,,,;ccc:;;cc:,.,:::cc:;;,,:c::c:;;,,::::;:::;,,;:cc:;'.,:ccc,.
//,;:;;:c::ccccccc:cc:ccc::;;;;;;;'';;;;''',,',;:c::c:;,,.''...',:c:::::,.':cc::;;;:::cc:::;,'';:;,'''''''',;::;'.';::::;.
//,;::;;:::c:::c:::cc:ccc:cccc::::;,,,,;'..';,'',;:::;,,,,,,,,',;;:c:cc:'.';;:;,,::;,,,;::c:;'.','''..,,,,,,;;,..'',;:::,.
//;:::;::;:::;:::::cc:ccccccccc;:c:,,:;;,'.';;;,..''',;::;;:;'.,::ccccc:,..,,,,;cc:::;;;;:::,'..,,,,;;:;;;:::;..,:;',::;'.
//;;:;;::;,;;,;:::ccccccccccccc:;::;,;;;:;'':::;,'..;c:;,;;;;,,',:clccc:'.,,'';ccccccc::;,,'',,'';;;:ccc:;:c:'':ccc;,,',,.
//;;::;;:;',;;;;::cccccccccccccc::;,,:::;;,',:::;:'.,;,..;:::::;',ccccc;.,;;;::ccc::c:;,,'.';::'.;::cccccccc,';cccc,',;;;.
//;,;:;;;;;::;,;:::ccc::::ccccccc:;'';;::,,,.'::;'..,,,',;::::c:;,;c::;'.,;:cc:;::;::,'...';;;,';c::cc:cccc:,;ccc:,'';;;,.
//;,,;;'',;;;;,,;::::::;;;::;::cc:;'';;:c;;;..;:,.';;,;:::ccccccc;,;::;'.,:ccc:;,,,,,'',,,,;;:;,;;;:cc::c:;,,;;;'';::;'.. 
//,,;:,',;;;,,,,'';:::;;;,,:::cc:::,,:cccccc;'';,';:,;cccccccccccc;,,::'.;ccccc;'.',;::;;:;;::,,:c:::c:::,'';,'',:c:;,'''.
//,;:c;,;;;::;,;,'';;;,',::::::;;::;,;:cc:cc:,','.;;,;cccc:cccccccc:,',..;::;,'''';cc:;;:c:::;'';c:;:c:;;..,,';ccc:,';;;,.
//;;;c:;;;:::;,;;;'',,;,,;::c::;;cc;'';:cc:c:,'''',;;:cccccccc:cccc:;'...'''''.',::cc;,;ccc:;::;;cc:;;;'..',',:c:;'',::;'.
//,;;:::;;::;,,;;::;,,,;;;:ccc:;;:c;'';:cc:c:,,'...;:cc:clcclccccc;,'.....,,;;'.,cc:;,,::::c;;cc;:c:;'....','.',,'',,,,;,.
//,,,,;;;:::;;::ccc:::;,;;;;:;,,;;;,,',:ccccc;,;'..,;cccccccc:,,;'.....',,;::,.':c:,,;;;;;;::,,;,''... ..'....''''',,'''..
//''.',,,,,,,:cccccccc;,;::::;'';:;,;,',:::c:,''...,:c::::;,'................. ..'..''...........       ... ........;,'''.
//,,'''''..,;::;,;;::;,,::;;:;;;:c:;;;;::::;''',...',,'....                                      ........     ..',',::,,,.
//,,,;;;;',c::;,,;;:;,,,;,,;,',;;::;;,,:;;,'..,'.           .................''...............,,','','''.......';:::::;;,.
//,,,:;,,',;,;;:::::;,,;;,,;,';;',:c:,';;''''''.         ..',;:;;,,,,,,,'..,;;;;;;:;,.'::,';;,:c::;;:;,'''''.....,:;,;::;.
//;,,;;;;,,;;;;:c:::;,,;::c:;,;:,;cc:,.......         ...,:::cccc;;;;;;;;;',;:;;:cc::'.;:',c;,:c;;,,;:;;:::::;,...,,';;;'.
//:;;::;'..;;;;;:::;,,,;::c:;,;:;;c:'..              .''',;;;;;::;;:::::::;',::;,;::;..,:,';:;;::::,'',::cccc;,'.....'''..
//c;:c:;,...,;;,,',,'',;:::,,;:;.....                .,;;;::;::::::ccccc:::;',:ccc;;:,..,'',::;;:c:,;:,,;;;;;,'''....,:;,.
//c;;c:;:;..';,,'.',;;;,;,'''''.       ...'..,,.......,;;;;;;;::cc::cccc::cc,':ccccc:;'...;cc::;;c:;;;;;;;;::::c;'.''.,;;.
//c:;::;;;'..,,;:;,',,'''....        ..,;::;;:c:;;;..''',;;;,;;;;;;;:::::;;:,';:ccccc:;..,:ccc:;,::;,;;cccccccccc;'.''..'.
//;,',;;,','.';;:;'''....        ....,::;:c:::cc:::,.',',;,,;;;;:::cccccc:::'';ccllccc:'.,cc:;;;,;,,;::cllcclcclcc:'.;,...
//:,,;;;;,,,..','....         ......,;::;:cccccc:::;',;,;::;:;,,;;,;;;;:::c:,';ccclccc:,.'::;,;;;,',:;;:c::::::ccc:;......
//::;::,,,'......         ....',,'.',;:::cccc:ccc:::,,;:ccc:cc::c:,;;,,,,,,,'..,;;,;;,,'.';;;;::;;;:cc::cccc:::::;,,,'... 
//::::,'....         .......',,;:;:;,,;:ccccc:ccccc:,',;clcclcccc:;:c:::::::;'..',,,''',..;:ccc;,;:::cccclcllccc:;;:c;'...
//;,,'.            ...,,,,'..,::::::;'';ccccc:cccc:;'..,cccccccc:::cccccccccc:,.';;,,'.,,.,::c:;,,;:::c:cccclccccccc:'.,,.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


contract MyceliumFidelity is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable
{
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public constant MAX_MYFI_PIECES = 10602;

    //mints that are reserved for educational purposes
    uint256 public constant EDUCATION_PIECES = 100;
    
    //mints that are reserved for friends and family of MyFi Studio,
    //and 50 for the studio allocation
    uint256 public constant FRIENDS_FAMILY_PIECES = 275;

    //links
    string public baseURI;
    string public licenseLink;

    
    address public creator;
    address public friendsAndFamilyMinter;
    address public educationMinter;
    address public vault;


    bool public friendsAndFamilyMinted = false;
    bool public educationMinted = false;


    //0.2 ETH
    uint256 public price = 200000000000000000;

    //keep track of what part of 
    //MyFi connection ritual we are in
    enum State {Init, ConnectionTime, Done}
    State public state = State.Init;

    constructor(string memory initialURI) ERC721('MyceliumFidelity', 'MYFI')
    {
        setBaseURI(initialURI);
        creator = msg.sender;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner 
    {
	baseURI = newBaseURI;
    }

    function openConnection() public onlyOwner 
    {
	state = State.ConnectionTime;
    }

    //This lets MyFi Studio update where
    //the official / canonical license lives.
    //  (**) (**)
    //   ||   ||
    //   ||  (**)
    //  (**)  ||
    //  (**)  ||
    //   ||  (**)
    //  (**) (**)
    function setLicenseLink(string memory ll) public onlyOwner
    {
	licenseLink = ll;
    }
    //Original License 
    //This license is an agreement between MyFi Studio and owners of MyFi ERC-721 NFTs minted on the following contract: TO BE DEPLOYED [S00N]. In this license, the phrase 'MyFi NFTs' are any NFTs minted on the above contract. Additionally, the 'media' of a MyFi NFT refers to any of the following:

    //The video content pointed to by the 'animation_url' metadata. This is an .mp4 file.
    //The audio content pointed to by the 'audio' metadata. This is an .wav file.
    //Any of the text metadata associated with the NFT.
    //The commercial rights granted by this license only apply during the span of time that the MyFi NFT is held in the owner's wallet. Commercial rights end as soon as the NFT is transfered out of the wallet.

    //MyFi Studio grants all owners of MyFi NFTs a non-exclusive license to the full commercial rights of the media of each MyFi NFT they own. MyFi studio also has full commercial rights to the media of every NFT from the MyFi collection. MyFi Studio shares commercial rights with owners so that the studio can use the collection media for future creative endeavours.

    //Any revenue from products that use the media from MyFi NFTs sold by MyFi NFT owners is royalty free, until the MyFi NFT owner has earned $1 million dollars of revenue. Once the owner has earned more than $1 million dollars of revenue, they must contact MyFi studio to obtain a license that contains a reasonable royalty on additional revenue.

    //Please give MyFi Studio credit when you use our content! We want you to use it for whatever you want, however let people know that you used our media. If you have any questions on how to acknowledge us, just send an email or DM.
    //Tell us when you're using your MyFi media! We want to know. It's cool!

    //MyFi Studio reserves the right to edit / update this license. the 'setLicenseLink' function above
    //is a mechanism for changing the licese. The license in this contract is just the initial launch license.
    //We thought it was important to include this in our contract, as it shines a light on how we hope
    //people will use and interact with MyFi. However, we look forward to people using MyFi in ways we never imagined.
    //  (**) (**)
    //   ||   ||
    //   ||  (**)
    //  (**)  ||
    //  (**)  ||
    //   ||  (**)
    //  (**) (**)

    function setEducationAddress(address em) public onlyOwner initState
    {
        educationMinter = em;
    }

    function setFriendsAndFamilyAddress(address fafm) public onlyOwner initState
    {
        friendsAndFamilyMinter = fafm;
    }

    //adjust the price of the NFT
    //only works when in Init
    function setPrice(uint256 _newPrice) public onlyOwner initState
    {
        price = _newPrice;
    }

    //Brings contract back to init state,
    //sets start block to very far in the future,
    //stops minting functionality
    function pauseMint() public onlyOwner connectingState
    {
        state = State.Init;
    }

    /// @notice Mint MyFi NFTs here :)
    /// @dev Each MyFi NFT costs 0.2 Eth.
    ///      In the first box write the total amount of Eth for the MyFi NFTs you are purchasing
    ///      In the second box write the total # of MyFi NFTs you are purchasing.
    ///      For example: if you are buying 4 MyFi NFTs:
    ///      in the first box put: 0.8
    ///      in the second box put: 4
    ///      Note: you can mint a maximum of 13 MyFi NFTs in each transaction. You can mint
    ///      more then 13 MyFi NFTs per wallet, however you must do it in multiple transactions.
    ///      @param myfiPieces The amount of MyFi tokens you are trying to mint. Must be an integer between 1 and 13.
    function connect(uint256 myfiPieces) public payable connectingState
    {

        require(totalSupply() < MAX_MYFI_PIECES, 'all MyFi pieces connected');
        require(myfiPieces > 0 && myfiPieces <= 13, 'You can connect to between 1 and 13 MyFi pieces at a time');
        require(totalSupply().add(myfiPieces) <= MAX_MYFI_PIECES, 'not enougn MyFi pieces available for connection, please chose a smaller ammount...');
        require(msg.value >= price.mul(myfiPieces), 'check your math: not enough eth sent');

        for (uint256 i = 0; i < myfiPieces; i++) 
        {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

	if(totalSupply() == MAX_MYFI_PIECES)
	{
	    state = State.Done;	
	}

    }

    function connectFriendsAndFamily() public friendsAndFamily
    {
        require(totalSupply() < MAX_MYFI_PIECES, 'not enough pieces remaining for friends and family allocation');
        require(totalSupply().add(FRIENDS_FAMILY_PIECES) <= MAX_MYFI_PIECES, 'not enougn MyFi pieces available for connection');
        require(!friendsAndFamilyMinted, 'friends and family already minted :p');
        
        friendsAndFamilyMinted = true;
        for (uint256 i = 0; i < FRIENDS_FAMILY_PIECES; i++) 
        {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function connectEducation() public education
    {
        require(totalSupply() < MAX_MYFI_PIECES, 'not enough pieces remaining for eduxation allocation');
        require(totalSupply().add(EDUCATION_PIECES) <= MAX_MYFI_PIECES, 'not enougn MyFi pieces available for connection');
        require(!educationMinted, 'education already minted :p');
        
        educationMinted = true;
        for (uint256 i = 0; i < EDUCATION_PIECES; i++) 
        {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    //according to https://wizard.openzeppelin.com/#erc721
    // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenID) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
       return string.concat(string.concat(baseURI, Strings.toString(tokenID)),".json");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    //end required by sol

    modifier friendsAndFamily
    {
        require(msg.sender == friendsAndFamilyMinter);
        _;
    }

    modifier education
    {
        require(msg.sender == educationMinter);
        _;
    }

    modifier connectingState 
    {
        require(state == State.ConnectionTime);
        _;
    }

    modifier initState 
    {
        require(state == State.Init);
        _;
    }

    function setVault(address newVaultAddress) public onlyOwner
    {
        vault = newVaultAddress;
    }

    function withdraw(uint256 _amount) public onlyOwner
    {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(_amount));
    }

    function withdrawAll() public payable onlyOwner
    {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(address(this).balance));
    }


}


//..            .....                                     ..   .....                                   .........   ..                              .      .....
//..               ....                                      .......                                 ...  ......  ....                           ...       ....
//..                   .....                          ..    .........                        .     ....     .....  ....      ..               .....        ....
//..                     .....                       ..    ....   .....                    .     .....        ..........  .....    ..      .....           ....
//..       ..          .       ...                 ...    .....     ......               .     ....             ..............  .       .....              ....
//..        .                    ....             ..    .....          ......          .     .....      ....      .............     ......                 ....
// ..  ...                          .....       ...    .....              .......   .     .....  ... ......         .........    ......                   .....
// ........                             ....   ...   .....                  .........   .....     ..... ...   ...     .....   .....                       .....
//..  .......                              .....    .....                      .......''''..   .  ...    .. .... ..     .........                          ....
//..      ......   ..                        ..   .....                            .......     .  ..     ....... ..      .........                         ....
//..          ........                     ..    ......                   ..     ... ......              .......     ....  .........                       ....
//..    ...        .....                 ...   .... .....               ..    ......    ......           .....    .......    ........                       ...
//... ........  ..     .  ....         ....   .....      ....         ..    ......         .......      ...     .....   ..     ........        .           ....
//... ......   ...         .....     ....   ........        .....  ...    .....              ......  .      .........    .       .........         .       ....
// .........   ...   ....       ........   ....  ...           .....    .....                   .....    .....    ...    .         .......     ....        ....
//   ............   ..... ...    ....,,'',;;'.    .              ..  ......                           ........    ...    .           ...........           ....
//.   ............  ..... ...   ....,;;:clc;..               ...   ........                        ...........   ...     .            .........            ....
//........   ..........   ....  ....'',;;;,......          ..    ....   ......                  .....   ......   ...     ..       ....  .........          ....
// .......  .....  ....  .........   .....    ....    ......   ......        .....           .........     .... ....           ........   ........         ....
// ......  .... ......  ........    ......    ...   ..............               .....    ....  ...   ...    .......      .......     ...   .......        ....
//.....   ....  .... .. .......   .......     ....   ......'''...                   . .......                   ....  ........           .    ......      .....
//..................  ........   .......... .........   .........            ...   ..........                    ........ ....            ..    .... .    .....
//.... .............  ......   ......   ...........   ......   ...       ..      .....     ......     ..       ...   ..........               ..',;;;,.   .....
//...  . ...   ....   .....   ........   ........   .......          ....   .......           .......      ........     .......            .....'''.'..   .....
//...  ............   ....  ..........   .  ...  .......                 ........                ............         .    .....     .......     .        .....
//..  .....   .............'''.....  ... ..','',,'.......      ....    ............        ...   ....''''....        ....   ............                   ....
//.  ......  ..........  ..................'';:c:;,'............    .......      .........   .............'..........     ..............                    ...
//.  .....   ........   .....................................    ......      .      ..............  ...    ......    ..........    ...............           ..
//  ...... .........  ................  ..... ......  ....    .....  .... .   ....    ..........       ....   ....................   ............            ..
// ....  .........   ...............  .......   .......    ......     .......     .......   ..........    .......'''''''............    .........            ..
//..... .........  ...............  ..........  .....    .....       ....   ............ ..      ..................  ..................    ........          ..
//.............   .............   ..............   ...  ..        ...     .....  ............    .............    ...    .................    .....         ...
//.............  .............   ..............    .....      .....   ............      ..............    .......   ......   ................    .....     .....
//..........   ...........   ..............    ...............    .......   ......     .................     ...............   .................  ....    .....
//. .......  ............  .............   ......... .....   ......... .....................      ............    .............   ................    .    ....
//.......   ..........   ............   ...........  ...  .............. ................   ....    ...............  ...............  .............         ...
// .....   .........   ...........   .............   ............... ................   ...     ......   .............................    .........         ...
//....   .........   ..........   ............... .............. ....................  .....   .......  ..  ..'..''''....... .............  .......         ...
//...   ........   .........   ........... ..............  ... ............ ..........  ....    ..............................................   ....      ....
//......','''..  ..........  ........... ............................. .................   .................  ...... .............. ..............   ..    .....
//.....,;;;;,'........... .........   .....................................................................................  ..........  ............         ...
//..  .......  .......   .......  ...........  ...........  ......  .............................................................  ....   ............         ...
//...';;,,'.  .......  ........   .........   ............. ....... ...  .................   ..........................................   .......  .....       ...