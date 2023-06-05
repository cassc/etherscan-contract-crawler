pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Strings.sol";
import "reentrancyguard.sol";

/*                The challenges start on 01/06/2022 at 8pm UTC
                         at http://discord.gg/FMYyDXrDyz
                               '             '
                            ' '     '
                         ''''''''''  ' ''''''''' '''
                        ''''.''''''''''''' .''''''' ''''
                        ''''-.'.''.'.''..'.--''''-..''''
                        '' -:-:.'..--''-------..'./-+ '
                         ''-+s:.--::--------------o/o''
                        .-.-so//////:::-::--:///++s+o''.
                        /:+.oso++ooo+++++//+ooo+osss/-:/'
                        .o::/o+.'    ':sss:.'   '-so-:+:
                         -:++s:       'o+/        :+/:/'
                          ./:ss+:..-:+yyy+::-...:+s///'
                           ..:syysyyyoyyy:.:syyyyso.-
                             '+o+//:::+ss:.-::/+o:-
                              '--::///+++++/::---.
                         '' '-:+oooooooosoooooo++/' '''
                       '-/++++ss+ooo++++++++oooo++oo+/:.
                    '-:+++++oossoooosoosssssssooo+ssoo++:.'
                 ':osss+ooooooosoooooooooooosssso+sssoo+++/++-'
              '-+osssssoo+ooooooooosssosossssooooooo++ooo+ossso:.
             .osssssssssyyyyyyyyysso+:-.'''.:+ooosssssssossssssso+
             .+sssyhhhhhhhhhhhysooosyysso/+oooossyyhhhhhhhhysssss/.
             --/shhhhyyysooo/-.'''''-+ssyhys:...:/+oosyysssyyhyso--.
         .'  .--/syhhysy:''''''''' /ooo:-/oyy:- '''''..-./oshhys+:--  '.
        .-.   .:ossss+.:.''''''''. ..'   .:/::/''''''''''':sossss+.'  '-'
       '.--. '...-/++.''''''''''. '''   .o/-.-+''''''''''''./so+:.  '.-'''
      ''.----..''''''.'''''''''.'''''  ''-+/+:/.'''''''''''''-.'   '---.'''

T)tttttt h)                   A)aa                   h)      ##
   T)    h)                  A)  aa                  h)
   T)    h)HHHH  e)EEEEE    A)    aa  r)RRR   c)CCCC h)HHHH  i) v)    VV e)EEEEE
   T)    h)   HH e)EEEE     A)aaaaaa r)   RR c)      h)   HH i)  v)  VV  e)EEEE
   T)    h)   HH e)         A)    aa r)      c)      h)   HH i)   v)VV   e)
   T)    h)   HH  e)EEEE    A)    aa r)       c)CCCC h)   HH i)    v)     e)EEEE

                        Tailored by Prof. Seldon#8609
                      Email  [email protected]
                             Twitter @ProfSeldon
*/


contract TheArchive is Ownable, ReentrancyGuard, ERC721 {
    using Strings for uint256;
    bool public saleIsActive;
    bool public publicSaleIsActive;
    uint256 public nextTokenId;
    uint256 public maxTokenSupply;
    mapping(bytes32 => bool) public whitelistPasswords;
    mapping(uint256 => bool) public specialTokensIds;
    string private defaultURI;
    string private baseURI;
    event mint(uint256 _tokenId, string _method, string _hash);

    constructor() public ERC721("HashPass", "HASHP") {
        saleIsActive = false;
        publicSaleIsActive = false;
        nextTokenId = 5;
        maxTokenSupply = 2047;
        defaultURI = "notyetuploaded";
    }

    function getCurrentFinneyPrice() public view returns (uint64){
        return _checkCurrentMintingPrice()/(1e15);
    }

    function _checkCurrentMintingPrice() internal view returns (uint64){
        if (nextTokenId < 16) {
            return 0;
        } else if (nextTokenId < 32) {
            return 10000000000000000; // 0.01 Eth
        } else if (nextTokenId < 64) {
            return 20000000000000000; // 0.02 Eth
        } else if (nextTokenId < 128) {
            return 40000000000000000; // 0.04 Eth
        } else if (nextTokenId < 256) {
            return 80000000000000000; // 0.08 Eth
        } else if (nextTokenId < 512) {
            return 120000000000000000; // 0.12 Eth
        } else if (nextTokenId < 1024) {
            return 240000000000000000; // 0.24 Eth
        } else {
            return 640000000000000000; // 0.64 Eth
        }
    }

    // check for special ids that can't be minted by the public
    function _setNextTokenId() internal {
        while (specialTokensIds[nextTokenId]) {
           nextTokenId ++;
        }
        if (nextTokenId > maxTokenSupply) {
            saleIsActive = false;
        }
    }

    function _validateMintRequirements() internal { // uint price
        require(saleIsActive, "Minting is currently closed.");
        uint256 currentPrice = _checkCurrentMintingPrice();
        require(
            currentPrice <= msg.value,
            "Ether value sent is not correct."
        );
    }

    function _validateWhitelistPassword(string memory _password) internal returns (bool) {
        bytes32 _keccakPassword = keccak256(abi.encodePacked(_password));
        if (whitelistPasswords[_keccakPassword]) {
            whitelistPasswords[_keccakPassword] = false;
            return true;
        }
        return false;
    }

    function mintPublicRandom() public payable nonReentrant {
        require(publicSaleIsActive, "Public minting is currently closed.");
        _validateMintRequirements();
        _safeMint(_msgSender(), nextTokenId);
        emit mint(nextTokenId, "publicRandomMint", "");
        nextTokenId ++;
        _setNextTokenId();
    }

    function mintPublicSpecific(string memory hash) public payable nonReentrant {
        require(publicSaleIsActive, "Public minting is currently closed.");
        _validateMintRequirements();
        _safeMint(this.owner(), nextTokenId);
        emit mint(nextTokenId, "publicSpecificMint", hash);
        nextTokenId ++;
        _setNextTokenId();
    }

    function mintWhitelist(string memory hash, string memory password) public payable nonReentrant {
        require(_validateWhitelistPassword(password), "Your password is not valid.");
        _validateMintRequirements();
        _safeMint(_msgSender(), nextTokenId);
        emit mint(nextTokenId, "whitelistMint", hash);
        nextTokenId ++;
        _setNextTokenId();
    }

    // mint the special ids
    // they will be awarded during special events throughout the minting period
    function mintSpecialTokens(uint startId) public onlyOwner {
       for (uint _tokenId = startId; _tokenId < nextTokenId; _tokenId++) {
           if (specialTokensIds[_tokenId]) {
               _safeMint(_msgSender(), _tokenId);
               emit mint(_tokenId, "specialMint", "");
           }
       }
    }

    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPublicSaleState() external onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function setWhitelistPasswords(bytes32[] memory _passwords) public onlyOwner {
       for (uint i = 0; i < _passwords.length; i++)
        {
            whitelistPasswords[_passwords[i]] = true;
        }
    }

    function setSpecialMintsIds(uint16[] memory _ids) public onlyOwner {
       for (uint16 i = 0; i < _ids.length; i++)
        {
            specialTokensIds[_ids[i]] = true;
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        if (bytes(baseURI).length == 0) {
            return defaultURI;
        } else {
            return string(abi.encodePacked(baseURI, (tokenId).toString()));
        }
    }

    // Withdraw eth out of the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}