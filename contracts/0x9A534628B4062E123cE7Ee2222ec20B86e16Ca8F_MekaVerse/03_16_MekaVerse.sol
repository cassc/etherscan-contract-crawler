// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @author: miinded.com

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                              .--==-:.                              ///
//                                 ..-=++=:     -==****.                              ///
//                               +#%@@@@#+-:.  -=+****-                               ///
//                               +#@@%##*+-::--=+****:                                ///
//                 .::           =#%@%##*=-:--+****+.                                 ///
//                 .:::.         -***++-::--+*****:                                   ///
//                  .::::.      .==*+=--=+****##*=-:.                                 ///
//                   ..:::::::.:*-+#%%%##***#%%%#%##*+=:.                             ///
//                   ..:--==++++++#%%%%###%@%@%%%%###++=-..:.                         ///
//                      .:-=++****#%%#######%%%%%%%%%%%%%#+*+-.                       ///
//                          :=*****###%%@@@@@@@@@@@@@%@@@%%%%*=.                      ///
//                        :-==*#%@@@@@@@@@@@@@@@@@@%###%@@@##**=                      ///
//                       ::=#@@@@@@@@@@@@@@@@@@@@@@####%@@%#+===                      ///
//                      .-%@@@@@@@@%%%##*#@@@@@@@@@#####@@%%@*=++-.                   ///
//                      :*%%@@@@@@@*=#%%****###%%%#**##%@@%%@%%%###*:                 ///
//                      .#*%%@@%+:.:=*%%#+*##*=-*#**###%@@%@@@%@%###*                 ///
//                       +*##%@-  ..===+++*+=++*######%%@%%@@@@@@@%#*                 ///
//                      .+*+**@*:.=+++*++*#+-#%@####%%%%%%@%%@@@@%#=.                 ///
//                    :--*+*##@@@%%%@####%%%:#%@%####@@%%@%#%%%%*                     ///
//                   -+*+*++##%@@@@@@%++#%%@*%%@#%%#%@@%@@%####%=                     ///
//                   -#####=+%%@@@@@@@###%%%@%*#%%@@%@@%@@@%###%=                     ///
//                    ###*#++#%@@@@@@@%%%%%%@@@%%@%@@@@%%@@@%###=                     ///
//                    :+++#**#%%@@@@@@%%%%%@@@@@@@@@@@@@@%@@@%#*-                     ///
//                       -%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#-                     ///
//                        %@@#%@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@#-            :-::==-::///
//                        [email protected]@*@@@@@@@@@@%####%%@@@%%%@@@@@@%#**###+.  ..-: .=++*+*###*///
//                            [email protected]@@@@@%%@%####%%@@%%%##%%%%#*###%#%#+=++#%%**+++###***+///
//                             %@@@++*#%*=++**#######%###########%#+++=#@@%#%*+++**#%%///
//                              -+*=+=-::::::--==+*#**+++=-++++**#*+++=*@@@@%%%%##*+++///
//                          :*=-==-:.   .....:::--==++++--#%****#%#++*++%@@@%@@@@@@%%%///
//                        --===-...:::----=============++%@@%%###%%*+*++#@@@@%@@@@@@@@///
//                 .::-*%*--=-.::------========++++======+*%%%%%%%@#+*#**%@@@@%@@@@@@@///
//       :.:-=+%%---:*%*+==-::-----=====+=++++++++++*++===+*%%%#***++#%#*#%@@@@@@@@@@@///
//    :**#%[email protected]%%==--*@#*+=::-=--=====+++*+*++++*#%#++**+++++*%%##*****@@##%@@@@@@@@@@@///
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

contract MekaVerse is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant PRICE = 0.2 ether;
    uint256 public constant START_AT = 1;

    address public constant creator1Address = 0xCaE02A17288a40E702fc24161d8DDAEF1D546c23;
    address public constant creator2Address = 0xDc7C0ca1b4C3b89D9Fe8a73aA25ebdC35aE25797;
    address public constant devAddress = 0x3c5ff56De82eCAf0dCE4063CAf42c756C5C29f71;

    bool private PAUSE = true;

    Counters.Counter private _tokenIdTracker;

    string public baseTokenURI;

    event PauseEvent(bool pause);
    event welcomeToMekaVerse(uint256 indexed id);

    constructor(string memory baseURI) ERC721("MekaVerse", "MEKA"){
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalToken() <= MAX_ELEMENTS, "Soldout!");
        require(!PAUSE, "Sales not open");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint(uint256[] memory _tokensId, uint256 _timestamp, bytes memory _signature) public payable saleIsOpen {

        uint256 total = totalToken();
        require(_tokensId.length <= 2, "Max limit");
        require(total + _tokensId.length <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_tokensId.length), "Value below price");

        address wallet = _msgSender();

        address signerOwner = signatureWallet(wallet,_tokensId,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");

        require(block.timestamp >= _timestamp - 30, "Out of time");

        for(uint8 i = 0; i < _tokensId.length; i++){
            require(rawOwnerOf(_tokensId[i]) == address(0) && _tokensId[i] > 0 && _tokensId[i] <= MAX_ELEMENTS, "Token already minted");
            _mintAnElement(wallet, _tokensId[i]);
        }

    }

    function signatureWallet(address wallet, uint256[] memory _tokensId, uint256 _timestamp, bytes memory _signature) public view returns (address){

        return ECDSA.recover(keccak256(abi.encode(wallet, _tokensId, _timestamp)), _signature);

    }

    function _mintAnElement(address _to, uint256 _tokenId) private {

        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit welcomeToMekaVerse(_tokenId);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPause(bool _pause) public onlyOwner{
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(15).div(100));
        _widthdraw(creator2Address, balance.mul(42).div(100));
        _widthdraw(creator1Address, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function getUnsoldTokens(uint256 offset, uint256 limit) external view returns (uint256[] memory){

        uint256[] memory tokens = new uint256[](limit);

        for (uint256 i = 0; i < limit; i++) {
            uint256 key = i + offset;
            if(rawOwnerOf(key) == address(0)){
                tokens[i] = key;
            }
        }

        return tokens;
    }

    function mintUnsoldTokens(uint256[] memory _tokensId) public onlyOwner {

        require(PAUSE, "Pause is disable");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            if(rawOwnerOf(_tokensId[i]) == address(0)){
                _mintAnElement(owner(), _tokensId[i]);
            }
        }
    }
}