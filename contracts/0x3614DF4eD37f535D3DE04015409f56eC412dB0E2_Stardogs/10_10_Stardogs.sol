// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// MMMMMMMMMMMMMMMMWWWKOO0XWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWO:,,;,;:d0WWWMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMWWMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMO''loodo;.'cONMWWMMMMMMMMMMMMMMMMMMMMMWMMMMMMWNKkdllllxKWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMNc.cll0XXOl:''c0WWWMMMMMMMMMMMMMMMMMMMMWWMWNXkl:;,,;cc;.,OWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMK,'llONXXKklc:''dKNWMMMMMMMMMMMMMMMWWWMWXxc;,,,:oxkxloxc.:XMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMO',cdXNXXX0d:co;.':xNMWMMMMMMMMMMMMWX0kl,,:ccloxKNNNOcod.,0MWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMk.,cxNXXXXOo:,ldlc;.cKMWWMMMMMMMWKd:'.';oolclxO0XXXNXoco.,0MWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMx.,ckNXXXX0dl,:dxdd:.oNWWWWWWMMXd,';:ldxocoxxdkXNXXNXocl.;KMWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMx.,ckNXXNXxldc:dxolc''cccccccll;.:dxxxxo;:loox0XNXXNKlcc.lNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMk.,cxNXXX0xdo;;loloooodxxxxollc;:cldxxo;;ldxk0KXXXXN0cc,.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMO',co0KX0doollodxxxxxxOXXKkxxxxxxoodxxl:odoooxKNXXXNx:c.;XMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMK;.cldxkkl:ldxxxxxxxxxkK0kxxxxxxxxxxxxl;:lodoxKNXXN0c:,.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWo.:llolccoxxxxxxxxxxxk0kxxxxxxxxxxxxxxl:llllxKNKXKo:;.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWd.:dccccdxxxxxoloxxxxkOxxxxxxxxxxxxxxxxl;lddx0Ox0d::.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMXc.ldcldxxxxxxdlcoxxxxOkxxxxdoclxxxxxxxxxlclooodxlcc';0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMNl.,ldxxxxxdl;,':dxxxkOxxxxxdoclxxxxxxxxxxdol:cocco,.kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWMXc.cxxxood:',...cxxkOkxxxxoc:;';ldxxxxxxxxxxo:;cdo''OMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWMWo.lxxdccdl'...;dkOKKkxxxx:.,'...;oxxxxxxxxxxdlcc,'dNMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMK;'oxxxxxxxoc:lk0KXNNX0kxxo,.....;lxdoodxxxxxxxc.;KWWMMMMMMMMMMMMMMWMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMNl.cxxOKXXK0kxocclc:coOXXOxxdl::coxxxdddxxxxxxxxo.:XMWMMMMMMMMMMMMMMWKdkXWMMMMWWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWM0,'dxkKNXXNKxkx..,'...;0NXKOOkkkkkkO0KXXXKOkxxxxo.'kXWMMMMMMMMMMMMMNx,,;;dXMMMMWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMk.,xxOXNXXKd:kKc.....'dKXKkOKXXXXXXXNXXXXNK0kxxxd:.'xWMMMMMMMMMMMMNd'cKKo';OWWWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWM0,'dxkKNXXXKxcxxo;.,lOXNXKKXNKkolkXNXXXXXXXKOxxxd:''oXWWMMMMMMMMMWd.cKNXXO;'oXMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWMWd.;dxOXNXXNXk:',;'',ldxkkxol;'lk0XNXXXXXNK0kxxxxo;.:XMWMMMMMMMMWk';0NXXXNKl':0WMWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWk;'cOXXXXNXNO;:xo;:c:,.',,;lkXXXXXXNXXXKOxxxxdl,'lKMMMMMMMMMMMK;.xNXXXXNNXk,'xNMMWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMO'.cd0XXXXN0:,cclxdlc:codOXNXXXXXXXXXKOkkdl:,..oNMMMMMMMMMWMWd.,ldkOK0OOkxl'.o0XWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMK:'llcd0XXXXOo:cllodOXXNNNXXXXXXXXXXKkolc::c'',':lxXMMWWMMWMK;.odlcclc:c::lo,..;0MWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMW0c'':dxolkXXXXXK00KXXXXXXXXXNXXXXX0dlcccoddx:'lxl;,.;OWMMWWMWx.;xxxxxdddxdxxxl...;0WMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWd.,ol:lxlckXXXXXXXXXXXXXXXXNXXNXOoccoxxxxxd:'lxxxxxc,,lxOKNWNl.cxxxxxxxxxxxxxd;.'.,OWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMk''ldxolx000XK0XXXXXXXNNXNNNNXXNKxoxxxxddoc;;oxxxxxxddoc,,,;cl'.lxxxxxxxxxxxxxxc:l,.,OWWWMMMMMMMMMMM
// MMMMMMMMMMMMMWMWl.'lodxx0XXXXX00XXXXKK0OKK0KXXXXXXOxxxl;;::ldxxxxxxdxxxxxddlc;,',;:coxxxxxxxxxxllx;..:KMWMMMMMWMMMMM
// MMMMMMMMMMMMMMMWO,.cc:dkKNXXXXXXXXK0000OKKKXXXXXNKkdl:;coxkxxxxxxdodxxxxxxxxxxxdlc;,,;coxxxxxxxddx:...dWMWMMMMWMMMMM
// MMMMMMMMMMMMMMMMWd.,:;oxONXXXXXNNXNNNNNXXXXXXNX0kolox0KKK0kkxxxxoldxxxxxxxxxxxxxxxxdoc;,;cdxxxxxxd:'..cXMWMMMMMMMMMM
// MMMMMMMMMMMMMMMWMK:.'oKkoxKXXXXXNXXNXXXXXXNKkxolox0XNXXXX0kkxxocldxxxxxxxxxxxxxxxxxxxxxoc;,:oxxxxo:;,.;KMWMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMO'.lKN0llOXXXXXXXXXXXXNKxloxkKNXXXXNNX0kxxdlloxxxxxxxxxxxxxxxxxxxxxxxxxxo:,:oxxlllc.;KMWMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMK;,kXXNXOoox0XXX0KNXXXNK0KNNXXXXNNNXKOkxddooxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:,cdddxl.:XMWMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMWl.dNXXXN0odKXXKKXXXXXXXXXXXXXXXXXKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl,:dxx:.oWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWWMO',OXNNXXXXXXXXXXXXXXXXXXXXNNXK0kxxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;;do',0MMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNd.;x0KXNXXXXXXXXXXXNXXXKKK0Okxxxxxxxxxxxxooxxxxxxxxxxdolloxxxxxxxxxxxxxxxxxxo;;,.dWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMNo.;dkO0XNXXXXXXXXNX0Okkxxxxxxxxxxxxxxxxxo:oxxxxxxxoc:codxxxxxxxxxxxxxxxxxxxxl'.cXMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMNd.,dxx0XXXXNXXXKK0kxxxxxxxxxxxxxxxxxxxxd,:xxxxxdc,:oxxxxxxxxxxxxxxxxxxxxxxxx;.xWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMK;.,lxOXNXXXXXNkoxxxxxxxxxxxxxxxxxxxxxxd,,dxxxl,,:dxxxxxxxxxxxxxxxxxxxxxxxddl.cNMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMNc.,,;d0XXXXXXN0llxxxxxxxxxxxxxxxxxxxxxd,.:dxc.,oxxxxxxxxxxxxxxxxxxxxxxxxxddo',KMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMWd.;l;,;ok0XKKXNkccdxxxxxxxxxxxxxxxxxxdo;.'lc..:dxxxxxxxxxxxxxxxxxxxxxxxxdodo',0MWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWMO''lol:,';dkdoxOx:;oxxxxxxxxxxxxxxkkd,',,cc..lxxxxxxxxxxxxxxxxxxxxxxxxxxdodo.;XMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWMX:.dOkxdl:,;lddddc':xxxxxxxxxxxxk0kd;'cooo,.,dxxxxxxxxxxxxxxxxxxxxxxxxxxxdd:.oWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWWWd.lXNXK0Oko;,cxOk;;O0OkkkkkkO0KX0;.'oOOOo,,;cdxxxxxxxxxxxxxxxxxxxxxxxxxxxc.:KMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWM0',0NXXNX0Ol.';;c,,ONXXXKKXXXNNO;':cdkOOkkko;cdxxxxxxxxxxxxxxxxxxxxxxxxdc.;0MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWWX:.dNXXXXKk;'kXko,.xNXXXXNXXNXd,,oxdllloxkOOdc:coxxxxxxxxxxxxxddxxooddl,'lXMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMXxlc;,lk0XNNXo.lNWWWd.oNNNNNNXNKl..'........';:::,..';cllllollcccodxddoc,...:oxXWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMX:.:oO0OO0XXNO,,0MWWNo.;xkkkkkKNO'.................':cdkkkOOOOOkdlldxxxo,......,kWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWM0,.:oOdkXXX0x;'kWWWWo.;od00O0kkNk..,,''...........'dxkKOkKNNNXX0x;.,;;:;;;cloxOXWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWW0l;;;;:cc:::lOWWMMNl.cld0xxXklo;.oXXXKK000OOOkkxc,,,::,:llccc:::lxkO0KXNWWMMMMWWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWMMWWXKK000KXWWMWMMMMXd:;;;,;:;,;lkNMWWWWWMMMMMMMMWX0kxdddddxkO0XWWMMMWWWMMWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWWWWMMMMMMMMWNK0000KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

error NonExistentTokenURI();
error WithdrawTransfer();

contract Stardogs is ERC721, ERC2981, Pausable, Ownable {
    using LibString for uint256;

    address payable public constant DAYSTAR = payable(0x3dc000dC40c7b922ff14752A99951b9B30fb49A9);

    string public baseURI;
    uint256 public constant TOTAL_SUPPLY = 108;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 private tokenIdCounter = 1;
    uint8 public constant MAX_MINT = 5;
    bool private _paused = true;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        baseURI = "https://bafybeiauekgunr2l5jgcsgmj7a6zf5adnlyqh4tvks7spwwsxvzpn6us7y.ipfs.nftstorage.link/metadata/";
        _setDefaultRoyalty(msg.sender, 500);
        _pause();
    }

    function mintTo(address recipient, uint8 amount) public payable whenNotPaused {
        require(tokenIdCounter + amount <= TOTAL_SUPPLY, "Total supply exceeded");
        require(msg.value >= MINT_PRICE * amount, "Minimum mint price not paid (0.01 ETH)");
        require(amount <= MAX_MINT, "Max mint amount exceeded");

        for (uint8 i = 0; i < amount; i++) {
            _safeMint(recipient, tokenIdCounter);
            tokenIdCounter++;
        }
    }

    function airdrop() public onlyOwner {
        require(tokenIdCounter == 1);
        _safeMint(0x3cb059dC57f3B4Bb958d00D12343Fbda1901CDaF, 1);
        _safeMint(0x7B3E8cbA240827590F63249Bc6314713317a665b, 2);
        _safeMint(0x12c4d3ED87Bb2022b20D6Df4F578014f05Ee0ec8, 3);
        _safeMint(0xE5b831a4Be169D36cAE0a1394b070D2d8a05b244, 4);
        _safeMint(0xd00d42FDA98e968d8EF446a7f8808103fA1b3fD6, 5);
        _safeMint(0xd606424168D1F6da0E51F7E27d719208dD75fe47, 6);
        _safeMint(0xd606424168D1F6da0E51F7E27d719208dD75fe47, 7);
        _safeMint(0xd606424168D1F6da0E51F7E27d719208dD75fe47, 8);
        _safeMint(0xd606424168D1F6da0E51F7E27d719208dD75fe47, 9);
        _safeMint(0xd606424168D1F6da0E51F7E27d719208dD75fe47, 10);
        tokenIdCounter = 11;
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        // route 1/3 to daystar
        (bool daystarTx,) = DAYSTAR.call{value: balance / 3}("");
        if (!daystarTx) {
            revert WithdrawTransfer();
        }
        // route rest to payee
        (bool transferTx,) = payee.call{value: address(this).balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function self_destruct() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTokenIdCounter(uint256 _tokenIdCounter) external onlyOwner {
        // stupid idiot
        tokenIdCounter = _tokenIdCounter;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        // stupid idiot #2
        baseURI = _baseURI;
    }
}