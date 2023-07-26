// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@divergencetech/ethier/contracts/random/PRNG.sol";
import "./Compiler.sol";
import "./Base64.sol";

contract OnchainGas is ERC721AQueryable, Ownable {
  using PRNG for PRNG.Source;

  IDataChunkCompiler private compiler;
  address[9] private threeAddresses;
  uint256 public cost = 0.0025 ether;
  uint256 public maxSupply = 1000;
  uint8 public maxMint = 2;
  bool public publicSaleActive = false;
  string private rpc;

  constructor(
    address _compiler,
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7,
    address chunk8,
    address chunk9
  ) ERC721A("OnchainGas", "OGAS") {
    compiler = IDataChunkCompiler(_compiler);
    threeAddresses[0] = chunk1;
    threeAddresses[1] = chunk2;
    threeAddresses[2] = chunk3;
    threeAddresses[3] = chunk4;
    threeAddresses[4] = chunk5;
    threeAddresses[5] = chunk6;
    threeAddresses[6] = chunk7;
    threeAddresses[7] = chunk8;
    threeAddresses[8] = chunk9;
  }

  function setMintActive(bool _newMintActive) public onlyOwner {
    publicSaleActive = _newMintActive;
  }

  function setRpc(string memory _rpc) public onlyOwner {
    rpc = _rpc;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function mint(address to, uint256 mintAmount) external payable {
    require(publicSaleActive, "disabled");
    require(mintAmount > 0, "mint <= 0");
    require(
      _numberMinted(msg.sender) + mintAmount <= maxMint,
      "mint >= maxmint"
    );
    require(totalSupply() + mintAmount <= maxSupply, "Over supply");
    require(msg.value >= cost * mintAmount, "Not enough ETH");
    _safeMint(to, mintAmount);
  }

  function gift(address to, uint256 mintAmount) external onlyOwner {
    require(mintAmount > 0, "mint <= 0");
    require(totalSupply() + mintAmount <= maxSupply, "Over supply");
    _safeMint(to, mintAmount);
  }

  function availableMint(address to) public view returns (uint256) {
    return maxMint - _numberMinted(to);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    string memory threejs = compiler.compile9(
      threeAddresses[0],
      threeAddresses[1],
      threeAddresses[2],
      threeAddresses[3],
      threeAddresses[4],
      threeAddresses[5],
      threeAddresses[6],
      threeAddresses[7],
      threeAddresses[8]
    );

    string memory tokenIdStr = uint2str(tokenId);
    string memory gasPriceGweiStr = uint2str(block.basefee / 1000000000);

    return
      string.concat(
        compiler.BEGIN_JSON(),
        string.concat(
          compiler.BEGIN_METADATA_VAR("animation_url", false),
          compiler.HTML_HEAD(),
          string.concat(
            compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
            threejs,
            compiler.END_SCRIPT_DATA_COMPRESSED(),
            compiler.BEGIN_SCRIPT(),
            compiler.SCRIPT_VAR("tokenId", tokenIdStr, true),
            compiler.SCRIPT_VAR("gasPrice", gasPriceGweiStr, true),
            compiler.SCRIPT_VAR(
              "rpc",
              string.concat("%2522", rpc, "%2522"),
              true
            ),
            compiler.END_SCRIPT()
          ),
          "%253Cstyle%253E%250A%2520%2520*%2520%257B%250A%2520%2520%2520%2520margin%253A%25200%253B%250A%2520%2520%2520%2520padding%253A%25200%253B%250A%2520%2520%257D%250A%2520%2520canvas%2520%257B%250A%2520%2520%2520%2520width%253A%2520100%2525%253B%250A%2520%2520%2520%2520height%253A%2520100%2525%253B%250A%2520%2520%257D%250A%253C%252Fstyle%253E%250A%253Cscript%253E%250A%2520%2520window.onload%253Dasync()%253D%253E%257Blet%2520s%253Ddocument.body%252Cc%253DgasPrice%252Cu%253D!1%253Bconst%2520g%253Ddocument.createElement(%2522input%2522)%253Bg.type%253D%2522checkbox%2522%252Cg.id%253D%2522liveCheckbox%2522%253Bconst%2520h%253Ddocument.createElement(%2522label%2522)%253Bh.htmlFor%253D%2522liveCheckbox%2522%252Ch.innerText%253D%2522Live%2520update%2522%253Bconst%2520d%253Ddocument.createElement(%2522span%2522)%253Bd.style.position%253D%2522absolute%2522%252Cd.style.bottom%253D%252210%2522%252Cd.style.left%253D%252210%2522%252Ch.style.color%253D%2522white%2522%252Ch.style.marginLeft%253D%252210px%2522%252Cd.appendChild(g)%252Cd.appendChild(h)%252Cs.appendChild(d)%252Cg.addEventListener(%2522change%2522%252Ct%253D%253E%257Bu%253Dt.target.checked%252Cu%2526%2526(R%253D0)%257D)%253Bconst%2520E%253Ddocument.createElement(%2522div%2522)%253BE.style%253D%2522position%253A%2520absolute%253B%2520top%253A%252010%253B%2520right%253A%252010%253B%2520color%253A%2520white%2522%252CE.innerText%253D%2560Gas%2520price%253A%2520%2524%257BgasPrice%257D%2520gwei%2560%252Cs.appendChild(E)%253Bconst%2520n%253Dt%253D%253E(t!%253D%253Dvoid%25200%2526%2526(l%253Dt%25252147483647)%253C%253D0%2526%2526(l%252B%253D2147483646)%252C((l%253D16807*l%25252147483647)-1)%252F2147483646)%253Bn(tokenId)%253Bconst%257Bwidth%253Ab%252Cheight%253Af%257D%253Ds.getBoundingClientRect()%253Blet%2520H%253Df%252F2%252Ca%253Df*2%252CT%253D0%253Bconst%2520r%253Dnew%2520THREE.PerspectiveCamera(80%252Cb%252Ff%252C1%252C3e3)%253Br.position.z%253D1500%253Bfunction%2520G(t)%257Bt.isPrimary%2526%2526(T%253Dt.clientY-H)%257Dconst%2520i%253Dnew%2520THREE.Scene%253Bi.background%253Dnew%2520THREE.Color(0)%253Bconst%2520L%253Dnew%2520THREE.HemisphereLight(16777147%252C526368%252C1)%253Bi.add(L)%253Bconst%2520w%253Dnew%2520THREE.PointLight(16777147%252C1%252C1e3%252C0)%253Bw.position.set(0%252C0%252C150)%252Cw.lookAt(0%252C0%252C0)%252Ci.add(w)%253Bconst%2520p%253Dnew%2520THREE.WebGLRenderer(%257Bantialias%253A!0%257D)%253Bp.setPixelRatio(window.devicePixelRatio)%252Cp.setSize(b%252Cf)%253Bconst%2520C%253Dnew%2520THREE.CylinderGeometry(50%252C100%252Ca%252C32%252C1%252C!0)%253BC.translate(0%252Ca%252F2%252C0)%253Bconst%2520z%253Dnew%2520THREE.MeshPhongMaterial(%257Bcolor%253AMath.ceil(16777215*n())%252Cside%253ATHREE.DoubleSide%252CflatShading%253A!0%257D)%252Cv%253Dnew%2520THREE.Mesh(C%252Cz)%253Bv.position.set(0%252Ca%252F2%252C0)%252Ci.add(v)%253Bconst%2520A%253Dnew%2520THREE.MeshBasicMaterial(%257Btransparent%253A!0%252Copacity%253A.5%252Ccolor%253A16777147%252Cblending%253ATHREE.AdditiveBlending%257D)%252CM%253D20%252CB%253Dnew%2520THREE.BoxGeometry(M%252CM%252CM)%253Blet%2520y%253D%255B%255D%253Bfunction%2520x()%257Bconst%2520t%253DDate.now()%252Co%253Dnew%2520THREE.Mesh(B%252CA)%253Bo.delay%253DMath.floor(5e3*Math.random())%252Bt%252Co.position.set(10-20*Math.random()%252C2e5%252C10-20*Math.random())%252Co.rotation.set(n()%252Cn()%252Cn())%252Cy.push(o)%252Ci.add(o)%257Dfor(let%2520t%253D0%253Bt%253Cc%253Bt%252B%252B)x()%253Bconst%2520I%253D%255B%255D%252Cj%253D10%252BMath.ceil(10*n())%252CD%253Dnew%2520THREE.SphereGeometry(2%252C8%252C8)%252CS%253Dnew%2520THREE.MeshBasicMaterial%253BS.color.set(16777215)%253Bfor(let%2520t%253D0%253Bt%253Cj%253Bt%252B%252B)%257Bconst%2520o%253Dnew%2520THREE.Mesh(D%252CS)%253Bo.position.set(1e3-2e3*n()%252C1e3-2e3*n()%252C1e3-2e3*n())%252CI.push(o)%252Ci.add(o)%257Dfunction%2520P()%257Bconst%257Bwidth%253At%252Cheight%253Ao%257D%253Ds.getBoundingClientRect()%253BH%253Do%252F2%252Ca%253Do*2%252Cr.aspect%253Dt%252Fo%252Cr.updateProjectionMatrix()%252Cp.setSize(t%252Co)%252Cv.position.set(0%252Ca%252F2%252C0)%257Dresizer%253DP%252Cs.appendChild(p.domElement)%252Cs.style.touchAction%253D%2522none%2522%252Cs.addEventListener(%2522pointermove%2522%252CG)%252Cwindow.addEventListener(%2522resize%2522%252CP)%252CP()%253Blet%2520R%253D240%253Bfunction%2520k()%257Bif(requestAnimationFrame(k)%252Cu%2526%2526R--%253C0%2526%2526(R%253D240%252Cfetch(rpc%252C%257Bmethod%253A%2522POST%2522%252Cbody%253AJSON.stringify(%257Bjsonrpc%253A%25222.0%2522%252Cmethod%253A%2522eth_gasPrice%2522%252Cparams%253A%255B%255D%252Cid%253A1%257D)%257D).then(async%2520e%253D%253E%257Bconst%257Bresult%253Am%257D%253Dawait%2520e.json()%253BgasPrice%253DparseInt(m%252C16)%252F1e9%257D))%252CgasPrice!%253D%253Dc)%257Bif(gasPrice%253Ec)for(let%2520e%253D0%253Be%253CgasPrice-c%253Be%252B%252B)x()%253Belse%257Blet%2520e%253Dc-gasPrice%253Bfor(const%2520m%2520of%2520y)if(m.done%257C%257C(m.done%253D!0%252Ce--)%252Ce%253C%253D0)break%257Dc%253DgasPrice%252CE.innerText%253D%2560Gas%2520price%253A%2520%2524%257BgasPrice%257D%2520gwei%2560%257Dr.position.y%252B%253D.05*(200-T-r.position.y)%252Ci.rotation.y-%253D.005%252Cr.lookAt(i.position)%252Cp.render(i%252Cr)%253Bconst%2520t%253DDate.now()%252Co%253D.001*t%252CO%253DMath.sin(o)%253Bfor(const%2520e%2520of%2520y)%257Bif(e.delay)if(t%253Ee.delay)e.delay%253Dnull%252Ce.position.y%253Da%252F2%252B20%252B20*Math.random()%253Belse%2520continue%253Be.velocity%253De.velocity%257C%257Cnew%2520THREE.Vector3(0%252C-1%252C0)%252Ce.velocity.y-%253D.267%252Ce.position.add(e.velocity)%252Ce.position.y%253C-a%252F2%2526%2526(e.bounceCount%253Fe.bounceCount%253C3%253F(e.bounceCount%252B%252B%252Ce.velocity.y%253D-e.velocity.y*.2%252Ce.position.y%253D-a%252F2)%253Ae.done%253F(y.splice(y.indexOf(e)%252C1)%252Ci.remove(e))%253A(e.position.set(10-20*Math.random()%252C2e6%252C10-20*Math.random())%252Ce.bounceCount%253D0%252Ce.velocity.x%253D0%252Ce.velocity.y%253D-1%252Ce.velocity.z%253D0%252Ce.delay%253DMath.floor(5e3*Math.random())%252Bt)%253A(e.bounceCount%253D1%252Ce.velocity.x%253D8-16*Math.random()%252Ce.velocity.z%253D8-16*Math.random()%252Ce.velocity.y%253D-e.velocity.y*.2%252Ce.position.y%253D-a%252F2))%257D%257Dk()%257D%253B%250A%250A%253C%252Fscript%253E",
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("image", false),
          "data:image/svg+xml;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg"><text style="white-space: pre; fill: rgb(51, 51, 51); font-family: Arial, sans-serif; font-size: 82.5px;" x="1.113" y="112.193">Onchain Gas</text><path d="M 250.835 148.107 L 416.481 404.232 L 85.189 404.232 L 250.835 148.107 Z" style="fill: #',
                uint2hex(uint24(getTokenSeed(tokenId))),
                '; stroke: rgb(0, 0, 0);" shape="triangle 85.189 148.107 331.292 256.125 0.5 0 [email protected]" /><text x="50%" text-anchor="middle" style="white-space: pre; fill: rgb(51, 51, 51); font-family: Arial, sans-serif; font-size: 51.3px;" y="319.276">',
                gasPriceGweiStr,
                "</text></svg>"
              )
            )
          ),
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("name", false),
          "Onchain%20Gas%20%23",
          tokenIdStr,
          "%22" // no trailing comma for last element
        ),
        compiler.END_JSON()
      );
  }

  // via https://stackoverflow.com/a/65707309
  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function uint2hex(uint256 _i)
    internal
    pure
    returns (string memory _uintAsHexString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 16;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 16) * 16));
      if (temp > 57) {
        temp += 7;
      }
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 16;
    }
    return string(bstr);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function _extraData(
    address from,
    address, /* to */
    uint24 previousExtraData
  ) internal view override returns (uint24) {
    if (from == address(0)) {
      uint256 randomNumber = uint256(
        keccak256(
          abi.encodePacked(
            block.timestamp,
            blockhash(block.number - 1),
            msg.sender
          )
        )
      );
      return uint24(randomNumber);
    }
    return previousExtraData;
  }

  function getTokenSeed(uint256 tokenId) public view returns (uint256) {
    uint24 batchSeed = _ownershipOf(tokenId).extraData;
    return uint256(keccak256(abi.encodePacked(batchSeed, tokenId)));
  }
}