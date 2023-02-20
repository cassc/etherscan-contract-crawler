// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// MMMMMMMMMMMMMMMMMMWWWKOO0XWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWO:,,;,;:d0WWWMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMWWMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMO''loodo;.'cONMWWMMMMMMMMMMMMMMMMMMMMMWMMMMMMWNKkdllllxKWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMNc.cll0XXOl:''c0WWWMMMMMMMMMMMMMMMMMMMMWWMWNXkl:;,,;cc;.,OWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMK,'llONXXKklc:''dKNWMMMMMMMMMMMMMMMWWWMWXxc;,,,:oxkxloxc.:XMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMO',cdXNXXX0d:co;.':xNMWMMMMMMMMMMMMWX0kl,,:ccloxKNNNOcod.,0MWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMk.,cxNXXXXOo:,ldlc;.cKMWWMMMMMMMWKd:'.';oolclxO0XXXNXoco.,0MWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMx.,ckNXXXX0dl,:dxdd:.oNWWWWWWMMXd,';:ldxocoxxdkXNXXNXocl.;KMWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMx.,ckNXXNXxldc:dxolc''cccccccll;.:dxxxxo;:loox0XNXXNKlcc.lNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMk.,cxNXXX0xdo;;loloooodxxxxollc;:cldxxo;;ldxk0KXXXXN0cc,.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMO',co0KX0doollodxxxxxxOXXKkxxxxxxoodxxl:odoooxKNXXXNx:c.;XMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMK;.cldxkkl:ldxxxxxxxxxkK0kxxxxxxxxxxxxl;:lodoxKNXXN0c:,.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWo.:llolccoxxxxxxxxxxxk0kxxxxxxxxxxxxxxl:llllxKNKXKo:;.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWd.:dccccdxxxxxoloxxxxkOxxxxxxxxxxxxxxxxl;lddx0Ox0d::.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMXc.ldcldxxxxxxdlcoxxxxOkxxxxdoclxxxxxxxxxlclooodxlcc';0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMNl.,ldxxxxxdl;,':dxxxkOxxxxxdoclxxxxxxxxxxdol:cocco,.kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMXc.cxxxood:',...cxxkOkxxxxoc:;';ldxxxxxxxxxxo:;cdo''OMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWMWo.lxxdccdl'...;dkOKKkxxxx:.,'...;oxxxxxxxxxxdlcc,'dNMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMK;'oxxxxxxxoc:lk0KXNNX0kxxo,.....;lxdoodxxxxxxxc.;KWWMMMMMMMMMMMMMMWMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMNl.cxxOKXXK0kxocclc:coOXXOxxdl::coxxxdddxxxxxxxxo.:XMWMMMMMMMMMMMMMMWKdkXWMMMMWWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWM0,'dxkKNXXNKxkx..,'...;0NXKOOkkkkkkO0KXXXKOkxxxxo.'kXWMMMMMMMMMMMMMNx,,;;dXMMMMWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMk.,xxOXNXXKd:kKc.....'dKXKkOKXXXXXXXNXXXXNK0kxxxd:.'xWMMMMMMMMMMMMNd'cKKo';OWWWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWM0,'dxkKNXXXKxcxxo;.,lOXNXKKXNKkolkXNXXXXXXXKOxxxd:''oXWWMMMMMMMMMWd.cKNXXO;'oXMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMWd.;dxOXNXXNXk:',;'',ldxkkxol;'lk0XNXXXXXNK0kxxxxo;.:XMWMMMMMMMMWk';0NXXXNKl':0WMWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWk;'cOXXXXNXNO;:xo;:c:,.',,;lkXXXXXXNXXXKOxxxxdl,'lKMMMMMMMMMMMK;.xNXXXXNNXk,'xNMMWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMO'.cd0XXXXN0:,cclxdlc:codOXNXXXXXXXXXKOkkdl:,..oNMMMMMMMMMWMWd.,ldkOK0OOkxl'.o0XWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMK:'llcd0XXXXOo:cllodOXXNNNXXXXXXXXXXKkolc::c'',':lxXMMWWMMWMK;.odlcclc:c::lo,..;0MWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMW0c'':dxolkXXXXXK00KXXXXXXXXXNXXXXX0dlcccoddx:'lxl;,.;OWMMWWMWx.;xxxxxdddxdxxxl...;0WMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWd.,ol:lxlckXXXXXXXXXXXXXXXXNXXNXOoccoxxxxxd:'lxxxxxc,,lxOKNWNl.cxxxxxxxxxxxxxd;.'.,OWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMk''ldxolx000XK0XXXXXXXNNXNNNNXXNKxoxxxxddoc;;oxxxxxxddoc,,,;cl'.lxxxxxxxxxxxxxxc:l,.,OWWWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWMWl.'lodxx0XXXXX00XXXXKK0OKK0KXXXXXXOxxxl;;::ldxxxxxxdxxxxxddlc;,',;:coxxxxxxxxxxllx;..:KMWMMMMMWMMMMMMM
// MMMMMMMMMMMMMMMMMWO,.cc:dkKNXXXXXXXXK0000OKKKXXXXXNKkdl:;coxkxxxxxxdodxxxxxxxxxxxdlc;,,;coxxxxxxxddx:...dWMWMMMMWMMMMMMM
// MMMMMMMMMMMMMMMMMMWd.,:;oxONXXXXXNNXNNNNNXXXXXXNX0kolox0KKK0kkxxxxoldxxxxxxxxxxxxxxxxdoc;,;cdxxxxxxd:'..cXMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWMK:.'oKkoxKXXXXXNXXNXXXXXXNKkxolox0XNXXXX0kkxxocldxxxxxxxxxxxxxxxxxxxxxoc;,:oxxxxo:;,.;KMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMO'.lKN0llOXXXXXXXXXXXXNKxloxkKNXXXXNNX0kxxdlloxxxxxxxxxxxxxxxxxxxxxxxxxxo:,:oxxlllc.;KMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMK;,kXXNXOoox0XXX0KNXXXNK0KNNXXXXNNNXKOkxddooxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:,cdddxl.:XMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWMWl.dNXXXN0odKXXKKXXXXXXXXXXXXXXXXXKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl,:dxx:.oWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWWMO',OXNNXXXXXXXXXXXXXXXXXXXXNNXK0kxxxxxxxxxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;;do',0MMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMNd.;x0KXNXXXXXXXXXXXNXXXKKK0Okxxxxxxxxxxxxooxxxxxxxxxxdolloxxxxxxxxxxxxxxxxxxo;;,.dWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMNo.;dkO0XNXXXXXXXXNX0Okkxxxxxxxxxxxxxxxxxo:oxxxxxxxoc:codxxxxxxxxxxxxxxxxxxxxl'.cXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMNd.,dxx0XXXXNXXXKK0kxxxxxxxxxxxxxxxxxxxxd,:xxxxxdc,:oxxxxxxxxxxxxxxxxxxxxxxxx;.xWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMK;.,lxOXNXXXXXNkoxxxxxxxxxxxxxxxxxxxxxxd,,dxxxl,,:dxxxxxxxxxxxxxxxxxxxxxxxddl.cNMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMNc.,,;d0XXXXXXN0llxxxxxxxxxxxxxxxxxxxxxd,.:dxc.,oxxxxxxxxxxxxxxxxxxxxxxxxxddo',KMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMWd.;l;,;ok0XKKXNkccdxxxxxxxxxxxxxxxxxxdo;.'lc..:dxxxxxxxxxxxxxxxxxxxxxxxxdodo',0MWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWMO''lol:,';dkdoxOx:;oxxxxxxxxxxxxxxkkd,',,cc..lxxxxxxxxxxxxxxxxxxxxxxxxxxdodo.;XMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWMX:.dOkxdl:,;lddddc':xxxxxxxxxxxxk0kd;'cooo,.,dxxxxxxxxxxxxxxxxxxxxxxxxxxxdd:.oWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWWWd.lXNXK0Oko;,cxOk;;O0OkkkkkkO0KX0;.'oOOOo,,;cdxxxxxxxxxxxxxxxxxxxxxxxxxxxc.:KMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWM0',0NXXNX0Ol.';;c,,ONXXXKKXXXNNO;':cdkOOkkko;cdxxxxxxxxxxxxxxxxxxxxxxxxdc.;0MMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWX:.dNXXXXKk;'kXko,.xNXXXXNXXNXd,,oxdllloxkOOdc:coxxxxxxxxxxxxxddxxooddl,'lXMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMXxlc;,lk0XNNXo.lNWWWd.oNNNNNNXNKl..'........';:::,..';cllllollcccodxddoc,...:oxXWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWMX:.:oO0OO0XXNO,,0MWWNo.;xkkkkkKNO'.................':cdkkkOOOOOkdlldxxxo,......,kWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWM0,.:oOdkXXX0x;'kWWWWo.;od00O0kkNk..,,''...........'dxkKOkKNNNXX0x;.,;;:;;;cloxOXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWW0l;;;;:cc:::lOWWMMNl.cld0xxXklo;.oXXXKK000OOOkkxc,,,::,:llccc:::lxkO0KXNWWMMMMWWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWMMWWXKK000KXWWMWMMMMXd:;;;,;:;,;lkNMWWWWWMMMMMMMMWX0kxdddddxkO0XWWMMMWWWMMWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWWWWMMMMMMMMWNK0000KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

error NonExistentTokenURI();
error WithdrawTransfer();

contract Stardogs is ERC721, ERC2981, Ownable {
    using LibString for uint256;

    address payable public constant DAYSTAR = payable(0x3dc000dC40c7b922ff14752A99951b9B30fb49A9);

    string public baseURI;
    uint256 public constant TOTAL_SUPPLY = 100;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 private tokenIdCounter = 1;

    mapping(uint256 => uint256) private idToURI;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        setBaseURI("https://bafybeidemmfnynp53i4ikm6g2olyfwt4jvqwqprsgedc4qn3tahrwppwou.ipfs.nftstorage.link/metadata/");
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mintTo(address recipient) public payable {
        require(tokenIdCounter < TOTAL_SUPPLY, "Max supply reached");
        require(msg.value >= MINT_PRICE, "Minimum mint price not paid (0.01 ETH)");

        _safeMint(recipient, tokenIdCounter);
        idToURI[tokenIdCounter] = dumbRandom(tokenIdCounter);
        tokenIdCounter++;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, idToURI[tokenId].toString())) : "";
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

    function dumbRandom(uint256 id) internal view returns (uint256) {
        // returns number between TOTAL_SUPPLY and tokenIdCounter
        unchecked {
            return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, id)))
                % (TOTAL_SUPPLY - tokenIdCounter) + tokenIdCounter;
        }
    }

    function setBaseURI(string memory _baseTokenURI) public {
        baseURI = _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function self_destruct() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}