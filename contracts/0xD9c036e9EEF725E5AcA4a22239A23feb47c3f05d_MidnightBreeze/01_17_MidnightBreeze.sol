//
//                                [email protected]@%%%%%%%%%%%%%%%%%%%%%%%%@@+
//                               [email protected]@:                        :@@+
//                              [email protected]@:                          :@@+
//                             [email protected]@:                            :@@+
//                            [email protected]@:                              [email protected]@+
//                           [email protected]@:                                [email protected]@+
//                          [email protected]@:                                  :@@+
//                         [email protected]@:                                    :@@+
//                        [email protected]@:                                      :@@+
//                       [email protected]@:                                        :@@+
//                      [email protected]@:                                          :@@+
//                     [email protected]@:                                            :@@+
//                    [email protected]@:   :+###+:          -*##*=          .=*##*-   :@@=
//                     :.  :#@%%@@@=        [email protected]@#@@@#.        [email protected]@#@@@*    .:
//                       -#@@= @@+       [email protected]@#::@@:       :*@@*[email protected]%
//                    [email protected]@@#-   [email protected]@%%%#%%@@@*:   *@@####%%@@%+.  .%@%#######-
//
//
//
//                                          XX     XX
//                                           XX   XX
//                                            XX XX
//                                             XXX
//                                            XX XX
//                                           XX   XX
//                                          XX     XX
//
//
// .------..------..------..------..------..------..------..------..------..------..------..------..------.
// |T.--. ||E.--. ||R.--. ||M.--. ||I.--. ||N.--. ||A.--. ||T.--. ||O.--. ||R.--. ||N.--. ||Y.--. ||C.--. |
// | :/\: || (\/) || :(): || (\/) || (\/) || :(): || (\/) || :/\: || :/\: || :(): || :(): || (\/) || :/\: |
// | (__) || :\/: || ()() || :\/: || :\/: || ()() || :\/: || (__) || :\/: || ()() || ()() || :\/: || :\/: |
// | '--'T|| '--'E|| '--'R|| '--'M|| '--'I|| '--'N|| '--'A|| '--'T|| '--'O|| '--'R|| '--'N|| '--'Y|| '--'C|
// `------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'`------'

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

}

contract MidnightBreeze is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 private _unitCost;
    uint256 private _maxPurchase;
    uint256 private _maxTokens;
    string _hostedURI;
    bool _saleComplete;
    bool _preSaleComplete;
    address _devAddress;
    mapping (address => bool) _whitelist;
    mapping (address => bool) _whitelistMinted;



    event CloseSale(address indexed _from);
    event OpenSale(address indexed _from);


    constructor(uint256 maxPurchase, uint256 maxTokens) ERC721("MidnightBreeze", "MNB") {
        _unitCost = 69000000000000000; //initial price - 0.069 ether
        _maxPurchase = maxPurchase;
        _maxTokens = maxTokens;
        _saleComplete = false;
        _devAddress = msg.sender;
        _pause();
        _tokenIdCounter.increment(); //start token generation at 1 not 0
    }


    function whitelistAddress (address user) public onlyOwner {
        _whitelist[user] = true;
    }


    function whitelistAddress (address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            _whitelist[users[i]] = true;
        }
    }


    function devMint(address to, uint256 numberToMint) public onlyOwner onSale {
        require(_tokenIdCounter.current() <= _maxTokens, "Sold out!!");
        require(paused(), "Can only dev mint when contract is paused");

        _unpause();

        uint256 i = 0;
        do {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            i++;
        } while (i < numberToMint && i < _maxPurchase);
        //can only mint a max of whatever the max public purchase is per transaction

        pause();
    }

    function pause() public onlyOwner onSale {
        //tokens can only be paused before they are sold out
        _pause();
    }

    function startSale(string memory hostedURI) public onlyOwner onSale {
        require(paused(), "Sale is already open");
        _hostedURI = hostedURI;
        _unpause();
        emit OpenSale(msg.sender);
    }


    function startOpenSale() public onlyOwner onSale {
        _preSaleComplete = true;
    }


    function setBaseURI(string memory hostedURI) public onlyOwner {
        bool pauseState = paused();
        if (pauseState){
            _unpause();
        }
        _hostedURI = hostedURI;

        if (pauseState){
            _pause();
        }
    }

    function _baseURI() internal view override returns (string memory) {

        return _hostedURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function updateUnitPrice(uint256 unitPrice) public onlyOwner {
        _unitCost = unitPrice;
    }

    function whitelistedOrOpenSale(address user) public view returns (bool) {
        return (_whitelist[user] && !_whitelistMinted[user]) || _preSaleComplete;
    }

    function usedWhitelistMint(address user) public view returns (bool) {
        return _whitelistMinted[user];
    }

    function mintBreeze(uint256 mintNumber) public payable {
        require(mintNumber > 0, "Must mint more than 0 tokens!");
        require(_tokenIdCounter.current() <= _maxTokens, "All tokens sold!");
        require(msg.value == mintNumber.mul(_unitCost), "Wrong ETH amount!");
        require(mintNumber <= _maxPurchase, "Can't mint more than max!");
        require(whitelistedOrOpenSale(msg.sender), "Not whitelisted, used whitelist mint or Open Sale has not started!");

        uint256 i = 0;
        do {
                i++;
                if (!_preSaleComplete) {
                    _whitelistMinted[msg.sender] = true;
                }
               _safeMint(msg.sender, _tokenIdCounter.current());
               _tokenIdCounter.increment();
            } while (i < mintNumber && _tokenIdCounter.current() <= _maxTokens);

            uint256 remaining = mintNumber.sub(i);
            if (remaining > 0){
                //return any overspent funds for the last buyer
                payable(msg.sender).transfer(remaining.mul(_unitCost));
            }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    uint256 dev_cut = balance.div(10);
    payable(msg.sender).transfer(balance.sub(dev_cut));
    payable(_devAddress).transfer(dev_cut);
  }


  function withdrawTokens(IERC20 token) public onlyOwner {
    require(address(token) != address(0));
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  function endSale() public onlyOwner onSale {
      require(!paused(), "cannot close sale whilst paused");
      require(_maxTokens == totalSupply(), "cannot close sale before it's sold out");
      // once this action is completed the base URI cannot be changed
      // and contract cannot be paused.
      _saleComplete = true;
      emit CloseSale(msg.sender);
  }

  function unitCost() public view returns(uint256) {
      return _unitCost;
  }

  modifier onSale() {
        require(!_saleComplete, "Sale closed. Action cannot be completed");
        _;
    }
}