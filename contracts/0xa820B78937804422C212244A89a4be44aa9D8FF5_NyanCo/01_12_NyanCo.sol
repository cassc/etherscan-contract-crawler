// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
/*

                                               ..-------..`
                                           ..+uqWNMMMMMNkm+-.
                                         .(&dHMMMMMMMMMMMMNme+.
                                       .([email protected]@@@@@@[email protected]@@MMMNm&-.
                                      [email protected]@@@@[email protected]@[email protected]@[email protected]@MMMMHaJ..`
                                     ([email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@@@MMHNko.
                                   `([email protected]@@[email protected]@@@@[email protected]@[email protected]@@[email protected]@@@@HH#Ny_`
                                   [email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@@@M##NMS!`
                                  ([email protected]@@[email protected]@[email protected]@@@@[email protected]@[email protected]@@[email protected]@@@@@@[email protected]<
                                 [email protected]@@[email protected]@@@[email protected]@@@@@@@@@@[email protected]@@@@@#HR<    ` `  `
                       -(uss&-..([email protected]@@[email protected]@@@@@@@@@@[email protected]@[email protected]@@@@[email protected]@@@@@HMRx..(+uws+-
                    `.([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@MMHAdkHUUWHmx-`
                     (dH0I__([email protected]@[email protected]@HHMM9C<__(vHHl
                    .jW0C<[email protected]<!_(+z<<4HR-
                    (dHC<(zXXO+-_([email protected]@@@[email protected]<_.(zZ0C>_jWHz_
                   -jWH>_.(+zwQmAQkWMMMMMMMMMMMHHHHHHHHHHHMMMMMMMMMgmAQQqkyz+__(dNk-
                 ..udHkzudkWHqqHkqkkkqkkkkkkqqqHHHHHHHHHHHkkkkkkkqqqqmmgggHHHkmzdWHs-.
             ..([email protected]@ggM#MNm&+-. `
          .([email protected]@HHHHUUUVTC<<<<<~~~____________~~~~~~~<<[email protected]@[email protected]+- `
        .(dHMMHHpWWWHmHMHMM9V><~_` ```` `     `         `            ``` [email protected]@@[email protected]
       (dWMHHbWmmHHWWWWHHSC!``             `   ` ` `  `  `   `  `         `[email protected]@@@@MMk+-`
    `.jXMMHqmHHWXuuuzXyWC>`     `      `  `  `    `  `    `  `   ` `         [email protected]
     (WMHWXUUXuuzzzvzXWC! `   `  ` ``  `    `  `      `  `  `  `  ` ` `` `     zWHkbkkkkqqHHggMHNI_
     (HMKuzzzvzvvrrtwyS<`   `  `     `  `  `    ` ` `  `        `         `  ``(wHqbbbkkkkkqqmHHNI~`
     (WMHkvvvvrrrtttwZ0_     `   `    `    `  `    `    ` ``       ` `  `       +WgHbbbkkkkkqgMH#I`
    `.zHMHkwrrrtllltw0I`` ` ` ` ` ``   -jAo_   `     `    ` +Qs- `  `` ` ` `  ` (dgHbbbbkkkqHMMMD!
      _?WMNkkwtl==zrwZ>   `` ....... ` _?7<`   ` .---. `    ?T=` ` ....... ``   _zHHbbbbkHHMMM9C!
        _?TMMMkmAzzOwZ<  ` `._((++---.`  `   `  .jWM9C_  `    ` ` -((J++-~~    `_jHHHWHHHHMM9Y!
           _?7WMMNHkkI<   `  _~?7TU0I< `     .(&<_~<! -++- `    `-zwVVT7>__ `  `-jHMMMMM9Y7!`
             ` `(XHMHI_      ```         ` `-zZ<`      (dR_      `     ``    `   (WMMK<~
              .(dXHU>`   `      `  .. ``   `(tI_      `.jk<`` ` ` _-.``  `    ` ` ?ZHHA+_
             (dHHSI_    `  ` ` -++rZI>_`  `  ?Owz-----(zZ3_    ``_OVZz+-.` `     `` +XHMR>
             (OHHms+- `   `   _<?<!`     `     ??CCOv77<!`   `      _??<!`  `  `` -JudHMSI
               <vHMMR< `    `  `     `  `       `        `  `    `   `       ` ` .dMNM96!`
                 ?XMHx-. `      `  `  `   ` `           `  `  `   `    `  `  ` .(iQMM9!`
                ` ?VWHHmx- ` `   `     `   `  `       `        `   `  `  ` ` .(dHMM9C!`
                    _?THHm-.  `   ` `   `    `  ` `  `  ` ` `   `   `  ``  .(uXM9=!`
                       ?THHm&+-. `  `  `  `    `   `     `   `  ` ` `  .(JuQWHHC!              `  .-
         ``              ?7TWHkA+-...  ` `  `   `     `    `  ``  ..(J+QkHH9YC!              ` .(+uw
          .(+-_ `           _?TWHkQQAs&+-----...-(&uux+-.----(((+uQQNMMH9C!`         ` .--.    _jXUU
          (wWWk+- `            (dWMMMMNMMMHkkkQQWWWUUWHHkkkWHHMMMNMMMMR<`            .jdWHA+.    _~`
         ` _1XWWk<_           [email protected]@[email protected]@[email protected]<ZHHo_         ` (jHHUWHk>
             _?1z~ `        `.zXW$_ ` [email protected]<<_ `  +WHk_        .(dW9C<jkbl_
*/
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract NyanCo is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _nyanCoIdCounter;

  // Royarlty
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  uint256 public secondarySaleRoyalty = 10_00000; // 10.0%
  uint256 public modulo = 100_00000; // precision 100.00000%
  address public royaltyReceiver;

  uint256 public maxNyanCo = 200;
  string public baseURI;
  string public extension = '.json';

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initialBaseURI,
    address _royaltyReciver
  ) ERC721(_name, _symbol) {
    setBaseURI(_initialBaseURI);
    setRoyaltyReceiver(_royaltyReciver);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function bulkmint(address _to, uint256 _num) public onlyOwner {
    require(_nyanCoIdCounter.current() + _num <= maxNyanCo, 'Cannot mint any more.');
    for (uint256 i = 0; i < _num; i++) {
      _nyanCoIdCounter.increment();
      uint256 nyanCoId = _nyanCoIdCounter.current();
      _safeMint(_to, nyanCoId);
    }
  }

  function tokenURI(uint256 nyanCoId) public view virtual override returns (string memory) {
    require(_exists(nyanCoId), 'ERC721Metadata: URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, nyanCoId.toString(), extension))
        : '';
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setExtension(string memory _extension) public onlyOwner {
    extension = _extension;
  }

  function setRoyaltyReceiver(address _newRoyaltyReceiver) public onlyOwner {
    royaltyReceiver = _newRoyaltyReceiver;
  }

  function setModulo(uint256 _newModulo) public onlyOwner {
    modulo = _newModulo;
  }

  function setSecondarySaleRoyalty(uint256 _newSecondarySaleRoyalty) public onlyOwner {
    secondarySaleRoyalty = _newSecondarySaleRoyalty;
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = royaltyReceiver;
    royaltyAmount = (_salePrice / modulo) * secondarySaleRoyalty;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId) || interfaceId == 0x2a55205a; // ERC165 Interface ID for EIP2981
  }
}