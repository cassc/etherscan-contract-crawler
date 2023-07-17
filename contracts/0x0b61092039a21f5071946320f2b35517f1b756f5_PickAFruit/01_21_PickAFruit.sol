// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author: https://ethalage.com

//
//                                            ;░▒╠╠╬╬╬╬╬▒░░
//                                       ;φ▒╣╣╬╬╬╬╠╬╬╬╬╬╬╬╣╣▒░
//                                    φφ▒╠╠╬╬╣▓▓▓╬╬╬╬╬╬╬╣▓▓╬╬▒░_
//                                 ]φ▒╬╬╬╣╬╬╬╬╩╩╚╙╙╙╙╙╙╚╬▓╬╬╬╠▒░
//                               φφ╠╬╬╬╬╬╬╩╩╙Γ         ]║▓╬╬╬╬╩░
//                             ,φ╠╬╬╬╬╬╬╩Γ___        .φ╠╬╬╬╣╬▒"
//                            φ╠╬╬╬╬╬╬╩⌐     '"Γ'  .,φ╢╬╬╬╬╬╬░
//                          ]φ╠╬╬╣▓╬▒░__     _  _ ;▒╬╬╬╬╬╬╩░
//                          φ╣▓╬╬╬╬╬▒▒░___ _    ░φ╠╣╣╣╣╬╬╚Γ
//                        .φ╠╬╬╣▓╬▒╠╠╬▒_____    φ╣╬╬╬╬╬╩Γ
//                      ,φ╠╣╬╬╬╬▓▓▓╬╩╙"____     ╠╣▓▓╬╠Γ'
//                  ]φ▒▒▒╠╬╬╬╬╬╬╠╣▓▓▒ ____ _  .░╠╣▓▓▓▒_
//                φφ╠╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬░  ._     φ▒╢╣╬╬╬╠φε
//              ,φ╠╬╬╬╬╬╬╩╩╩╩╬╬╬╬╬╬╠░,;'__   .φ╠╬╬╬╬╬╬╬╠φ≥,
//             ]╠╣╬╬╬╬╬╚⌐___'!└.;φ╠╬╠▒░░_  .,φ╠╬╬▒╠╬▓╬╬╬╬╬▒φ≥,
//            .φ╢▓▓▓╬▒└│░░____;░φ╠╠╬╬╬▒░╔╔φ▒╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬▒░,
//           .φ▒╠╬╬╬╬░_'░░__.;φ╠╬╬╩╠╣▓▓▓▓▓█╬▒░░_______'░╠╬╬╬╬╬╣▒░,
//           ]╠╬╬╬╬╠▒░ _'___░φ▒╠╩╚░░╚╠╬▓▓╬╩╠╠╬▒φ░____..'""╚╠╬╬╬╣╣╬░
//           ]║╬╬╬╠▒░_ .░░__φ╠╬▒Γ░░░░░╠╬╬▒░Γ╙╠╠╬╠▒░∩__'_░░░╙╚╠╣╬╬╬╠▒░
//           ░║╬╬╬╠▒░_ _!'__░║╬▒░░░░░░░╠╠░░░░░╚╩╠╬╬▒φ░_''░'_░╚╠╬╬╬╣╬▒~
//           ░╠╬╬╬╬▒░░__'__ ╠╣╬╠░░░░░░░╚▒░░░░░░░╚╩╬╬╬▒░__'.░░░░╠╣╬╬╬╠▒░
//           !╠╬╬╬╬╬▒░ _;.__╠╣▓╬▒▒░░φ▒▒░░φφ░░░░░░░╚╬▓╬▒φ░ '░░_'░╠╬╬╬╬╣╠░
//            ╙╚╠╬╬╬╬░__"'_ ╠╫▓╣╬╬▒▒╣▓╬▒░▒╠▒░░░░░░░╚╬╣▓▓▒░░░"'.!Γ╚╠╬╬╬╬▒ε
//             ]╠▓╬╬╬▒░,____░╟╣▓▓╬╠╣▓█▓▒░▒╠▒░░░░░░░░░╠╣▓╣╬▒░_''__!╚╬╬╬╬╬╬▒
//             ^╠╬╬╬╬╬╬▒⌐___░╠╬╬╣╬╣▓██▓╬▒▒░░▒▒░░░░░░░░╚╠╣█╬▒░_____'░╠╣▓▓▓╬░
//              "╚╠╣╣▓▓╬░___░╠╠╠╬╣▓▓▓██▓▓▒░░░░░░░░░░░░░╚╠╬╣▓╬▒ ____'╚╢╣▓▓╬░∩
//                ╚╢╬╬╬╬╬▒░ φ╠╬╠▒╬╣▓▓▓▓██▓╠▒░░▒▒▒░░░░░░░░╚╬╣▓▓▓▒░,__░╠╬╬╬╬▒░
//                '╙╚╬╣╬╬╬╬▒╬╬╬╬╬╬╬╣▓▓▓███▓▓╬╠▒╠▒╠▒░░░░░░░╚╩╬▓▓▓╬╬╬╬╬╬╣▓▓╬░_
//                  ^╙╩╬╬╣╣╬╬╬╬╬╬╣╣▓╬╬▓▓▓███▓▓╬▒╠╠╠╠▒▒░░░░░░╚╠╬╬▓▓╬╬╣╣▓▓▓╬⌐
//                     ╙╚╩╩╩╩╩╩╚╚╩╩╬╬╬╬╬▓▓████▓╬╠▒╠╠╠╠▒▒░░░░░░░╩╬╬╬╣╣▓▓▓▓╬░,
//                         "'      "╚╬╬╬╬╣▓▓▓▓▓▓▓▓╬▒░╚╠╠▒φ░░░░░░░╚╬╬╬╬╬╬╬╬╬▒⌐
//                                   "╚╠╬╬╬╬╣▓▓▓██▓╬▒░░░╚╠╠▒▒φφ░░░░░╠╬╬╬╬╣▓╬░
//                                      ╙╚╬╬╬╬╣██▓▓▓╬╬▒░░░░╠╠╠╬╠▒▒░░φ╠╬╬╣▓▓╬░
//                                        "╚╫╬╬╠╬╬╣▓▓▓╬╠╠▒▒▒▒▒▒╠╬╬▒▒╬╣▓╬╬╬▓╬░
//                                          '"╚╠╬╣╬╬╬╬╬╬╣╣▓▓▓▓▓▓▓▓╣╬╬╬╬╣╣╬╩╙
//                                             ""╙╙╚╠╬╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓╬╬╩╙'
//

import "./EthalageMinter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @custom:security-contact [email protected]
contract PickAFruit is EthalageMinter {
    using Counters for Counters.Counter;

    struct Fruit {
        string name;
        string image;
    }

    mapping (string => Fruit) private _fruit;
    mapping (uint256 => string) private _tokens;
    mapping (uint256 => bool) private _wrapped;

    string private _background = "ffffff";
    string private _backgroundUnwrapped = "333333";
    string private _description = "Pick a Fruit is an art project by [Maze de Boer](https://www.mazedeboer.com).\\n\\nVisit [this page](https://ethalage.com/collection/pick-a-fruit) for more info about this project.";
    uint256 private _initSupply = 355;
    uint256 public constant maxSupply = 10000;

    constructor() EthalageMinter("Pick a Fruit", "PAF", LicenseVersion.COMMERCIAL) {
        _tokenIdCounter._value = _initSupply;
        setArtist("https://www.instagram.com/mazedeboer/");
        setContractURI("https://ethalage.com/contracts/paf.json");
    }

    // Fruit

    /// @dev Add or replace fruit info
    function setFruit(string calldata _key, string calldata _name, string calldata _image) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Fruit storage f = _fruit[_key];
        f.name = _name;
        f.image = _image;
    }

    /// @dev Whether a fruit exists
    function fruitExists(string calldata _key) public view returns (bool) {
        return bytes(_fruit[_key].name).length > 0;
    }

    // Mint

    /// @dev Mint exitsting token
    function mintExisting(uint256 id_, address to_, string calldata key_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (id_ <= _initSupply);
        require (fruitExists(key_));
        _tokens[id_] = key_;
        _wrapped[id_] = true;
        _safeMint(to_, id_);
    }

    /// @dev Mint new token
    function mint(address to_, string calldata key_) external onlyRole(MINTER_ROLE) {
        require (totalSupply() < maxSupply);
        require (fruitExists(key_));
        _tokenIdCounter.increment();
        _tokens[_tokenIdCounter.current()] = key_;
        _wrapped[_tokenIdCounter.current()] = true;
        _safeMint(to_, _tokenIdCounter.current());
    }

    // Unwrapping

    /// @dev Set background color for wrapped tokens
    function setUnwrappedBackground(string calldata _color) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _backgroundUnwrapped = _color;
    }

    /// @dev Whether a token is wrapped
    function isWrapped(uint256 _tokenId) public view returns (bool) {
        require(_tokenId <= _tokenIdCounter.current(), "Token must exist");
        return _wrapped[_tokenId];
    }

    /// @dev Unwrap token
    function unwrap(uint256 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_wrapped[_tokenId], "Token must be wrapped");
        _wrapped[_tokenId] = false;
    }

    // Metadata

    /// @dev Set background color for wrapped tokens
    function setBackground(string calldata _color) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _background = _color;
    }

    /// @dev Set token description
    function setDescription(string calldata _new) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _description = _new;
    }

    /// @dev Get token name
    function _getName(uint256 _tokenId) private view returns (string memory) {
        return string(abi.encodePacked("#", Strings.toString(_tokenId), " ",_fruit[_tokens[_tokenId]].name));
    }

    /// @dev Get string for wrapped status
    function _getUnwrapped(uint256 _tokenId) private view returns (string memory) {
        if (_wrapped[_tokenId] == true) {
            return "No";
        }
        return "Yes";
    }

    /// @dev Get token background color
    function _getBackground(uint256 _tokenId) private view returns (string memory) {
        if (_wrapped[_tokenId] == false) {
            return _backgroundUnwrapped;
        }
        return _background;
    }

    /// @dev Get metadata for a token
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId <= _tokenIdCounter.current(), "Token must exist");
        return string (
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "',
                            _getName(_tokenId),
                            '", "description": "',
                            _description,
                            '", "background_color": "',
                            _getBackground(_tokenId),
                            '", "attributes": [{"trait_type": "Fruit", "value": "',
                            _fruit[_tokens[_tokenId]].name,
                            '"}, ',
                            '{"trait_type": "Unwrapped", "value": "',
                            _getUnwrapped(_tokenId),
                            '"}], "image": "',
                            _fruit[_tokens[_tokenId]].image,
                            '"}')
                    ))));
    }

}