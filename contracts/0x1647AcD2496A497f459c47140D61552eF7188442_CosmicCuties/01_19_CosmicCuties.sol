// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// artist: Jen Stark
/// title: Cosmic Cuties
/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "./ERC721CollectionBase.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//    ╟█]█▄└█▒▌░█▐█ █▀▄─▀╒█▒▒█╬▒▒░░╠╠╬░░╠▒░░░∩░╙╠╬╬╬╬╠╩░░░░╙╚░░░░░░╠╠╩╚╠░░█▄╛\▄└┐╓▌"░░     //
//    ▄▄█▓█▀╬▌╠▓█`█▄▌▓╬███╬╬▓╬▒╩╠▒▒╚╚╠╬╬╬╬╦░░░░≥░╠╠░╩░░░░░░░░φ░φ░░░Γ╚░░╚░¼└▀▄µ╟▓█▀ j▌^    //
//    ╫╬╠╬▒▒╠╬▌░█▌╙▀╓█▒╣╩╫░▒╠¼╣▄▌╙░░░▒╠╚░╠╠╣▓▓███▓▄░░░░░░φ░░░░░░░φ╠▒╠╠░░░╙█▓└█_▀,#█_█▓    //
//    ░▀▒▄▌╟▒╠╬▓╬████╠╬░╬░▀▀▓▀╓│╔╬╠▒░╙░φ▒▓▓█████████▄_º░░╙▒φ░φ▒░#╬╠╩╚╩░░╙█ ╓▌╙▌╓▀,╙█_▀    //
//    ▓▒▀╩@▒╫▄▒╠▒▓▓▓▒▒φ▓██▓╦│@▓▓▓▓█▒▒░░╣▓▓╬╚╚░░░░░╙╚█╕\ \7ε╙╠╬╠╬╬╩╙φφQΓ║▌╟█▀█µ╙▀▄█µ╫█▄    //
//    █╬░╬█▓░╙▓▄▀░╡│╠█▀╠╩╠╬█╬█▒╬█▒╝╩░░╣█╬╠▒▒░░░░░░__╫▒∩'_┌²░└╚╚╠╬▒░░╬╣█ █ ╓▌╙█_▄▀_█╓_█    //
//    ╢█▓█▒█▓▒╙▀@▓█▒╣▌╠░╠░╠╫█╠╩╠╠╠░╠φ╣█▓╬╠▒▒▒░░░░∩__╙╬░_[__\⌐_░╚▒░φ╣╠╠█▄╙█▀╟▌╫█▀▄▌└╙█▄    //
//    ╬█▒╬╩╠╬█╣╬█▓╬██╠▒φ░░╠╠▒╩╔░░░░▒╬▓█╬╬▒▄▄▒▒░░▒▄▄▄φ╠░_░_'."__░░░φ╣▓░╟█▓▓█▄█⌐╓█▀╙▀▌╙█    //
//    ╬╬╬░φ░╠╣██▒╩╚╬▒╠░╠▒▒╙╝╩░╬╠╬╠▒φ╠██╬╬████╬░╚▓███▓▓▌⌐░⌐'__'_⌠╠╬╬╠╣▓╣▒╫▒╬█_██▄██_█      //
//    ╠╩░░░░╠╠█▒╬╫▒╠╢╩░░╠╠φ#φ░╚╩╠╬▒▒╟▓█╣█████▒░░╙╢╬█╬╬█░░░___.⌐_╚╠╠╬╠╬╬╠╠╣╬█_▀j█▓╣▌╫▌█    //
//    ▒░Γ░░░▐╬╬╬▒╚`Σ░▄╬░╚▒░▒╬▒░░░╠╬╠╣██╬╩╚╩╠╬░░░░¡░░░'╟▒φ░_.~;__]▓╠╠╬╠╠╠▒╠╬██▄█▌╬╬█ █     //
//    ░▒▒╬╬▒░╬╬╬▒╓φ╩▒╬╠▒▒╠▒░▒╬▒╬░░╠╣███╬▒▒▒╣█▓▓▀∩░░░░░▐▒╠░__⌐_'_!╟▌╠╠╬╠╠╠▒╠╠╬╬▒▒▒▒█▄,█      //
//    ▓╬╬╬╠╬░░▒▒╠╩▒╬╚╬╬╬╣╬╬▒╠╬▒╠▒▒░╠╫▓██╬╬╬╬╬╙░.¡░░░░░╟▒╠Γ__[..._░╟▒╠╠╫▌▒╠╠╠╠╬╠╠╠╠▒╬▀╬     //
//    ╬╠╩░░╩░▒▒╟▒╠╩▄▓▒╬╬╬╬╬╠╚▒▒╚╬▒¼▒╫▓██╬╬╣█▓▀▀▀▀▀╩░░░╬░▒│_'░_'¡_"╚█▒▓▀█╬╠╠╢▓╙▌╠▒╠╠╠▒╠     //
//    ▒░φ▒▒▒φ▒╬▒╚▒╟╬╬▓▒╚║╬╬╠▒╠╬▒░╠░░╠╣▓██╣▓▓▓╬╩Θ░░░░▒╣▒░╬░_'"'~;-.░╙▀▒░╟▓▓█▀░░╚▀█╠╠╠╬▌     //
//    ▒╠▒▓▒╠╠╣▒▓▓▓▓▒╙▓▓▄▓╬╬╠╣╬╬╬▒╚░░╠╫╣▓██▓╬╬▒▒░░░░▄▓█▒║╠▒_.:.[░░¡░░░░░░█▒╡░░░Γ░╟▓▌╬█╚     //
//    ░╠▒╫▓▓▓▓╣▓╟▌╔▓▌╚▓▓╩╫╬▓╩╚╣╬╠╠╠░╠╬╣████▓▓▓███████▓▒╬╠░⌐¡░∩░░░░▒░]▓▄░░░░╓█▓▄░░╚╚█▒░    //
//    ░╠╢▓░╫▓▒╙▒▌▄▓▒╟▌▄▒▓░▓▒▓▓╬╬╬╬╬░░╣╬╣███▓▓╬▓▓▓╬╬▓▓▌░╬▒░_»░⌐┌\░φ¼▓▓╩╠▌░░▓█╚▄╠█░░░░░░    //
//    ╠╠▓╬█░▄▓▓▓╬▀▓██╬▓█╣▓░▓▌╬╫█╣▀▒░φ╣╬▓▓▓██▓╬╬╬╬╠╬╣▓▌░▒▒░░\░░';░░░╩Γ▄░█▒]█▒▓▀░╢▄▓▒░░░    //
//    █╬╣█╫█╬▓▌▒███╝██▓██╬██╢██╬▒▒░░▒╠╬╬╣╬██▓╬╬╬╬╬╣▓▓▒░╠▒░¡;░';░░░░░#╠░╣▌╫▌░╓█▒╠█╩▓▄░▓     //
//    ▀╓╚█▒▓████▓╝░G╙╙╬╩▀▒Å▒╢║▓╣╬▒░φ▒╬╠░╬╫▓╬╣╬╩╬╬╣╬╣▓▒░╠▒░░░░.░░░]╦░░╬░╠██╬Γ█▐▌║┘▓╚█░█     //
//    #▓Ç╠██╩.╬╩░╗▓█▓▒φ╬╬╣▀╩▒╩╣╨╠╠░╚╠╫░░⌠╠╬╙╚Γ░░░╚╠╬▓▒╚╠▒░░░φ░░░░\╙▒▒φφ▒╚▒"█▀█ █▐█▒╣██     //
//    █╫▓⌐╝╨╔╬└╔╣█▄▓▄▓▓╬▓█▌▀▌#▒╥δ▒^φ╠░];░▒╩;░░¡░░Γ╚╣╬▒╠╠╠░░░░░░░Γ¼╠▒╙╢╣▒≥▒╣▌╫▓█▄█▒▒╚╩╚     //
//    ▄▌█▒╔▄██▒╣█▓▓╬╬█▓█▌╬Γ█╙╩ó▒▀├;╚░∩_¡░▒▒└║▓Θ▓▒█▓██▒╠╬▒░░!░░░¡⌠φ╙╢╬╦▒╚╚▒▓p▌_ └╚▓▓▓╬▓     //
//    ██╟▓╫▓▄▌██▒█╢█▌▓▓▌█φ█└╙▌▒┘▄░░░▒∩'░δ░╬_▒▒╫▓██╬█╬▒╟█▒░░!░░░░░Γ╠░╫▓▓╠▄▒╣▓▌╦___╙╣╬██     //
//    ╙╫╠█▌▓▌▓▌╬█▓▓▌██╣█▌▓▓╙╬▌╪▓⌐└░╬░];'░▒░:▐╬█▓╬▌█▓▒╬╚▓╠╫░:"░░7╛╠#╣░╫▌▌╬╡▓█▄▌▄___ '└└    //
//    █▓▌╬╫█▒╠╬╬╬▓▓█▓█▀▓▀██▌╬▓╬╬];╫▒Γ║,;]▒░⌡▐╬╙╢╬╬╣╝▒╣▒╬╠▓▌φ~░∩^Ö¼▓▌▀░▐▓▒╬▓╬█▓╬µ______    //
//    ▄█╙██▐╬▒▓╬███▄▓█▌╬██▌█▓╣Σ▄/φ▀⌠;▌;"▐╬(╔╟╬▒╣╠╬╢╠▓╬▌╠▒╬▒╟▒'¡½╙▐▌▀█▓╙╬╬╣╬╬╬╣▓╬______     //
//    ╙▄█▄╙█╬▒╫╬█╙██╬▓█████▄█╟╠▒▒║Ö░╔▌⌠[░╩Å▌╬███▌╬╣▓█╫█░░╣▒▐▒';½╙▒╟▌╟█╣╬╬╝╠╬╬╬╬▒▒_____     //
//    ▀▀▄██▓▓╣█╣¼╠╠╬╫╬╢▓█╫▌█▒╠╬▒Γ▐░╠╫▌⌠φ╚░╣╠▓╣▓╣█▓█╬╟█╙▒Γ,░⌡░░:¼▐╠,▓█▓██▓▓╫▓╝╠╩║╠╣▄___     //
//    ██╠█▌╓▒▓▓████▄╬▓╬╬██████▓▒∩╢å▒▓▌[║▒╠╬╟░▒▓╣██▓╣╬╬▓▌╠╠Å└φ▐░▐╟╠▀╣▌█████▓▓╬▒╠╠▓╬╣▌__     //
//    ▄▄█▄╙▀█▌│█▒██▓▓██▓▓████╬█▒▌░╬▒╣▒░╠╦▓╬╬╬╬████╬▓▓╬╬▌╙å╬⌠▄█▒▒▄╣▓▌███████▓█╬▓▓▓▓╟▌__     //
//    ▀╓▄█▀█▌█████╣╬╬╠╩╠╬▓███▓▓▓▌╠╬▒╬░▐▓██▓╣╬▓█╣▓██▓╬╣╬█▓▒▒▓▓█▌▐▌╣██████▓███▓████╩¬___    //
//    ██▐██▌█████▓╬╬▒▒▒╠╣▓███▓▓╣╬╣╣▓╬░╫▓█▓██▓▓╣▓▓▓▓███╫▓▓▓▓▓▓╫▒▓█▓╣███████████┘  _____    //
//    █▒█╬╬██╬╬╬╬╣╬╩▒▒▒╠╣▓███▓█╬╬▓▓▓╣╩▒█╣▓▓▓███████╣███▓▓╣▓▒╣╬Å╟╠╣████╬╬▒░░╚╠╬________     //
//     └╙└╙└ __ _└ __   └╙╙└╙╙╙'╙└╙└  _└└╙╙╙└ └└ ╙╙╙╙└└╙└└'└└└_└'_└└╙└└______  ____ _     //
//                                             _,╓╓,__                          __        //
//             _▀▀███▓▀Γ                    ▄█▀╙└─└╙██                       _ª██▀        //
//               _██▌                     _▓█▀      __                        ]█▌_        //
//              _▐██_                     _██▄_          ▄                    ██_         //
//              ]██¬  __▄▄ _ ╓▄_ _,▄▄_    _╙██▌ _    _ ▄█═    _ ,_▄▌ ,▄_ _▄▄ ▓█  ,▄▄ _    //
//              ██▌ _▄█▀_╟█"▀██_▄▀└╟█b     _╙████▄_ _╙╠██▀┘ ,▓▀╙╙██_└▀█▌▄▀██▐█Q#▀╙└██_    //
//            _╟██_╓█▌╓▄█▀'_▓█▄▀__╓█▌_▄▌     _└▀███   ██_ ,█▀_ _▄█─ _▐█▓└ __██╙_╓▄█▀      //
//            ]██ ]██╙__ _▄███└   ██_j█\       _ ██▌_▓█¬_▄█▀__,██▀ _▄██_   ██▀██─         //
//            ██▌ ╟█▌__,▄▀┐██   _██,▄▀█         _╫█▌▐█▌▄███ ▄▀╙█▌_▄▀██_   ▐█_ └█▌_╓⌐      //
//           ▓█▌_ _▀▀▀▀╙ _╙▀    ╙▀▀╙ _└█▄_     _▄█▀_▀▀▀ ╙▀▀▀ _╙▀▀╙_╙▀_    ▀─  _└▀▀┘_      //
//         _▐█▀_                       _╙▀▀▓▄▄▓▀▀__                                       //
//    _██▓▄▓▀└                                                                            //
//    __─`__                                                                              //
////////////////////////////////////////////////////////////////////////////////////////////

contract CosmicCuties is ERC721CollectionBase, ERC721, AdminControl {
    constructor(address signingAddress) ERC721("Cosmic Cuties", "CC") {
        _initialize(
            // Total supply
            333,
            // Purchase price (None)
            0,
            // Purchase limit (None)
            0,
            // Transaction limit (None)
            0,
            // Presale purchase price (None)
            0,
            // Presale purchase limit (None)
            0,
            signingAddress,
            // Use dynamic presale purchase limit
            false
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721CollectionBase, ERC721, AdminControl)
        returns (bool)
    {
        return
            ERC721CollectionBase.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount)
        external
        override
        adminRequired
    {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses)
        external
        override
        adminRequired
    {
        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(
        uint256 startTime_,
        uint256 duration,
        uint256 presaleInterval_,
        uint256 claimStartTime_,
        uint256 claimEndTime_
    ) external override adminRequired {
        _activate(
            startTime_,
            duration,
            presaleInterval_,
            claimStartTime_,
            claimEndTime_
        );
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix)
        external
        override
        adminRequired
    {
        _setTokenURIPrefix(prefix);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _prefixURI;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override(ERC721, ERC721CollectionBase)
        returns (uint256)
    {
        return ERC721.balanceOf(owner);
    }

    /**
     * @dev mint implementation
     */
    function _mint(address to, uint256 tokenId)
        internal
        override(ERC721, ERC721CollectionBase)
    {
        ERC721._mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTranfser}.
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        _validateTokenTransferability(from);
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        adminRequired
    {
        _updateRoyalties(recipient, bps);
    }
}