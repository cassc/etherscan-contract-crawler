// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Compiler.sol";
import "./Base64.sol";
import "./IMetaDataURI.sol";

contract OnchainCheckRenderer is IMetaDataURI, Ownable {

  IDataChunkCompiler private compiler;
  address[9] private threeAddresses;
  string private rpc;
  uint256 private immutable MAX_MINT_GAS_PRICE = 1000000; // 1000 gwei mint would show all checks
  IMetaDataURI public upgradeContract;

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
  ) {
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

  function setRpc(string memory _rpc) public onlyOwner {
    rpc = _rpc;
  }

  function setUpgradeContract(address _upgradeContract) public onlyOwner {
    upgradeContract = IMetaDataURI(_upgradeContract);
  }

  function tokenURI(uint256 tokenId, uint256 seed, uint24 gasPrice)
    public
    view
    returns (string memory)
  {
    if (upgradeContract != IMetaDataURI(address(0))) {
      return upgradeContract.tokenURI(tokenId, seed, gasPrice);
    }
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
    string memory gasPriceGweiStr = gasPriceToStr(gasPrice);
    string memory gasPriceIntegerInGweiStr = uint2str(
      gasPrice / 1000
    );
    bool isDark = seed % 2 == 0;
    string memory numberOfCheckMarks = uint2str(getNumberOfCheckMarks(seed, gasPrice));

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
          "%253Cstyle%253E%250A%2520%2520*%2520%257B%250A%2520%2520%2520%2520margin%253A%25200%253B%250A%2520%2520%2520%2520padding%253A%25200%253B%250A%2520%2520%257D%250A%2520%2520canvas%2520%257B%250A%2520%2520%2520%2520width%253A%2520100%2525%253B%250A%2520%2520%2520%2520height%253A%2520100%2525%253B%250A%2520%2520%257D%250A%253C%252Fstyle%253E%250A%253Cscript%253E%250A%2520%2520%2522use%2520strict%2522%253Bwindow.onload%253D()%253D%253E%257Blet%2520m%252Ca%253Ddocument.body%252Cc%253DgasPrice%252Cu%253D!1%253Bconst%2520G%253Dt%253D%253E%2560%253C%253Fxml%2520version%253D%25221.0%2522%2520encoding%253D%2522UTF-8%2522%253F%253E%250A%253Csvg%2520version%253D%25221.1%2522%2520viewBox%253D%25220%25200%252024%252024%2522%2520xmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%253E%250A%253Cg%2520fill%253D%2522%2524%257Bt%257D%2522%253E%250A%253Cpath%2520d%253D%2522M22.25%252012c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.66-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.33%25202.19c-1.4-.46-2.91-.2-3.92.81s-1.26%25202.52-.8%25203.91c-1.31.67-2.2%25201.91-2.2%25203.34s.89%25202.67%25202.2%25203.34c-.46%25201.39-.21%25202.9.8%25203.91s2.52%25201.26%25203.91.81c.67%25201.31%25201.91%25202.19%25203.34%25202.19s2.68-.88%25203.34-2.19c1.39.45%25202.9.2%25203.91-.81s1.27-2.52.81-3.91c1.31-.67%25202.19-1.91%25202.19-3.34zm-11.71%25204.2L6.8%252012.46l1.41-1.42%25202.26%25202.26%25204.8-5.23%25201.47%25201.36-6.2%25206.77z%2522%2520fill%253D%2522%25231d9bf0%2522%252F%253E%250A%253C%252Fg%253E%250A%253C%252Fsvg%253E%2560%252Cz%253Dt%253D%253E%257Bconst%2520o%253Dnew%2520THREE.TextureLoader().load(%2560data%253Aimage%252Fsvg%252Bxml%252C%2524%257BencodeURIComponent(t)%257D%2560)%252Cb%253Dnew%2520THREE.MeshBasicMaterial(%257Btransparent%253A!0%252Copacity%253A.65%252Ccolor%253A16777147%252Cblending%253ATHREE.AdditiveBlending%252Cmap%253Ao%257D)%252Ce%253Dnew%2520THREE.PlaneGeometry(128%252C128)%252Cd%253Dnew%2520THREE.Mesh(e%252Cb)%253Breturn%257Btexture%253Ao%252Cmaterial%253Ab%252Cgeometry%253Ae%252Cmesh%253Ad%257D%257D%252Cy%253Ddocument.createElement(%2522input%2522)%253By.type%253D%2522checkbox%2522%252Cy.id%253D%2522liveCheckbox%2522%253Bconst%2520h%253Ddocument.createElement(%2522label%2522)%253Bh.htmlFor%253D%2522liveCheckbox%2522%252Ch.innerText%253D%2522Live%2520update%2522%253Bconst%2520r%253Ddocument.createElement(%2522span%2522)%253Br.style.position%253D%2522absolute%2522%252Cr.style.bottom%253D%252210%2522%252Cr.style.left%253D%252210%2522%252Ch.style.color%253D%2522white%2522%252Ch.style.marginLeft%253D%252210px%2522%252Cr.appendChild(y)%252Cr.appendChild(h)%252Ca.appendChild(r)%252Cy.addEventListener(%2522change%2522%252Ct%253D%253E%257Bu%253Dt.target.checked%252Cu%2526%2526(M%253D0)%257D)%253Bconst%2520f%253Ddocument.createElement(%2522div%2522)%253Bf.style%253D%2522position%253A%2520absolute%253B%2520top%253A%252010%253B%2520right%253A%252010%253B%2520color%253A%2520white%2522%252Cf.innerText%253D%2560Gas%2520price%253A%2520%2524%257BgasPrice%257D%2520gwei%2560%252Ca.appendChild(f)%253Bconst%2520l%253Dt%253D%253E(t!%253D%253Dvoid%25200%2526%2526(m%253Dt%25252147483647)%253C%253D0%2526%2526(m%252B%253D2147483646)%252C((m%253D16807*m%25252147483647)-1)%252F2147483646)%253Bl(tokenId)%253Bconst%257Bwidth%253AR%252Cheight%253AE%257D%253Da.getBoundingClientRect()%253Blet%2520T%253DE%252F2%252Ci%253DE*2%252CP%253D0%253Bconst%2520s%253Dnew%2520THREE.PerspectiveCamera(80%252CR%252FE%252C1%252C3e3)%253Bs.position.z%253D1500%253Bfunction%2520A(t)%257Bt.isPrimary%2526%2526(P%253Dt.clientY-T)%257Dconst%2520n%253Dnew%2520THREE.Scene%253Bn.background%253Dnew%2520THREE.Color(0)%253Bconst%2520B%253Dnew%2520THREE.HemisphereLight(16777147%252C526368%252C1)%253Bn.add(B)%253Bconst%2520w%253Dnew%2520THREE.PointLight(16777147%252C1%252C1e3%252C0)%253Bw.position.set(0%252C0%252C150)%252Cw.lookAt(0%252C0%252C0)%252Cn.add(w)%253Bconst%2520p%253Dnew%2520THREE.WebGLRenderer(%257Bantialias%253A!0%257D)%253Bp.setPixelRatio(window.devicePixelRatio)%252Cp.setSize(R%252CE)%253Bconst%2520x%253Dnew%2520THREE.CylinderGeometry(50%252C100%252Ci%252C32%252C1%252C!0)%253Bx.translate(0%252Ci%252F2%252C0)%253Bconst%2520O%253Dnew%2520THREE.MeshPhongMaterial(%257Bcolor%253AMath.ceil(16777215*l())%252Cside%253ATHREE.DoubleSide%252CflatShading%253A!0%257D)%252Cv%253Dnew%2520THREE.Mesh(x%252CO)%253Bv.position.set(0%252Ci%252F2%252C0)%252Cn.add(v)%253Blet%2520g%253D%255B%255D%253Bconst%2520H%253Dz(G(%2522%25231d9bf0%2522))%253Bfunction%2520C()%257Bconst%2520t%253DDate.now()%252Co%253Dnew%2520THREE.Mesh(H.geometry%252CH.material)%253Bo.delay%253DMath.floor(5e3*Math.random())%252Bt%252Co.position.set(10-30*Math.random()%252C2e5%252C10-30*Math.random())%252Cg.push(o)%252Cn.add(o)%257Dfor(let%2520t%253D0%253Bt%253Cc%253Bt%252B%252B)C()%253Bconst%2520j%253D%255B%255D%252CI%253D10%252BMath.ceil(10*l())%252C%2524%253Dnew%2520THREE.SphereGeometry(2%252C8%252C8)%252Ck%253Dnew%2520THREE.MeshBasicMaterial%253Bk.color.set(16777215)%253Bfor(let%2520t%253D0%253Bt%253CI%253Bt%252B%252B)%257Bconst%2520o%253Dnew%2520THREE.Mesh(%2524%252Ck)%253Bo.position.set(1e3-2e3*l()%252C1e3-2e3*l()%252C1e3-2e3*l())%252Cj.push(o)%252Cn.add(o)%257Dfunction%2520S()%257Bconst%257Bwidth%253At%252Cheight%253Ao%257D%253Da.getBoundingClientRect()%253BT%253Do%252F2%252Ci%253Do*2%252Cs.aspect%253Dt%252Fo%252Cs.updateProjectionMatrix()%252Cp.setSize(t%252Co)%252Cv.position.set(0%252Ci%252F2%252C0)%257Da.appendChild(p.domElement)%252Ca.style.touchAction%253D%2522none%2522%252Ca.addEventListener(%2522pointermove%2522%252CA)%252Cwindow.addEventListener(%2522resize%2522%252CS)%252CS()%253Blet%2520M%253D240%253Bfunction%2520L()%257Bif(requestAnimationFrame(L)%252Cu%2526%2526M--%253C0%2526%2526(M%253D240%252Cfetch(rpc%252C%257Bmethod%253A%2522POST%2522%252Cbody%253AJSON.stringify(%257Bjsonrpc%253A%25222.0%2522%252Cmethod%253A%2522eth_gasPrice%2522%252Cparams%253A%255B%255D%252Cid%253A1%257D)%257D).then(async%2520e%253D%253E%257Bconst%257Bresult%253Ad%257D%253Dawait%2520e.json()%253BgasPrice%253DparseInt(d%252C16)%252F1e9%257D))%252CgasPrice!%253D%253Dc)%257Bif(gasPrice%253Ec)for(let%2520e%253D0%253Be%253CgasPrice-c%253Be%252B%252B)C()%253Belse%257Blet%2520e%253Dc-gasPrice%253Bfor(const%2520d%2520of%2520g)if(d.done%257C%257C(d.done%253D!0%252Ce--)%252Ce%253C%253D0)break%257Dc%253DgasPrice%252Cf.innerText%253D%2560Gas%2520price%253A%2520%2524%257BgasPrice%257D%2520gwei%2560%257Ds.position.y%252B%253D.05*(200-P-s.position.y)%252Cn.rotation.y-%253D.005%252Cs.lookAt(n.position)%252Cp.render(n%252Cs)%253Bconst%2520t%253DDate.now()%252Co%253D.001*t%252Cb%253DMath.sin(o)%253Bfor(const%2520e%2520of%2520g)%257Bif(e.lookAt(s.position)%252Ce.delay)if(t%253Ee.delay)e.delay%253Dnull%252Ce.position.y%253Di%252F2%252B50%252B20*Math.random()%253Belse%2520continue%253Be.velocity%253De.velocity%257C%257Cnew%2520THREE.Vector3(0%252C-1%252C0)%252Ce.velocity.y-%253D.267%252Ce.position.add(e.velocity)%252Ce.position.y%253C-i%252F2%2526%2526(e.bounceCount%253Fe.bounceCount%253C3%253F(e.bounceCount%252B%252B%252Ce.velocity.y%253D-e.velocity.y*.2%252Ce.position.y%253D-i%252F2)%253Ae.done%253F(g.splice(g.indexOf(e)%252C1)%252Cn.remove(e))%253A(e.position.set(10-20*Math.random()%252C2e6%252C10-20*Math.random())%252Ce.bounceCount%253D0%252Ce.velocity.x%253D0%252Ce.velocity.y%253D-1%252Ce.velocity.z%253D0%252Ce.delay%253DMath.floor(5e3*Math.random())%252Bt)%253A(e.bounceCount%253D1%252Ce.velocity.x%253D8-16*Math.random()%252Ce.velocity.z%253D8-16*Math.random()%252Ce.velocity.y%253D-e.velocity.y*.2%252Ce.position.y%253D-i%252F2))%257D%257DL()%257D%253B%250A%250A%253C%252Fscript%253E",
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("image", false),
          "data:image/svg+xml;base64,",
          Base64.encode(
            bytes(
              generateSvg(seed, gasPrice)
            )
          ),
          compiler.END_METADATA_VAR(false)
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("attributes", true),
          "%5B%7B%22trait_type%22%3A%22gas%20at%20mint%22%2C%22value%22%3A",
          gasPriceIntegerInGweiStr,
          '%7D%2C%7B%22trait_type%22%3A%22dark%22%2C%22value%22%3A%22',
          isDark ? 'true' : 'false',
          '%22%7D%2C%7B%22trait_type%22%3A%22number%20of%20checkmarks%22%2C%22value%22%3A',
          numberOfCheckMarks,
          '%7D%5D%2C'
        ),
        string.concat(
          compiler.BEGIN_METADATA_VAR("name", false),
          "Onchain%20Gas%20Check%20%23",
          tokenIdStr,
          "%22" // no trailing comma for last element
        ),
        compiler.END_JSON()
      );
  }

  function leftPad(string memory str, uint256 length) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory paddedBytes = new bytes(length);
    for (uint256 i = 0; i < length; i++) {
      if (i < length - strBytes.length) {
        paddedBytes[i] = "0";
      } else {
        paddedBytes[i] = strBytes[i - (length - strBytes.length)];
      }
    }
    return string(paddedBytes);
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

  /**
   * @dev generates a top and bottom grid of checkmarks made up of 8 colors separated by empty space in the middle. 
     The lower the intensity, the more checkmarks will be missing in the two grids.
   * In addition, print the intensity value in the center of the grid, divided by wei (gasPriceGweiStr)
   */
  function generateSvg(uint256 seed, uint24 gasPrice) public pure returns (string memory) {
    uint24 boostedGasPrice = gasPrice * getGasPriceMultiplier(seed);
    bool isDark = seed % 2 == 0;
    return string.concat(
      '<?xml version="1.0" encoding="UTF-8"?><svg aria-hidden="true" version="1.1" viewBox="0 0 512 688" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#',
      isDark ? '111111' : 'EEEEEE',
      '" />',
      generateTopGrid(seed, boostedGasPrice),
      generateGasPriceText(gasPrice, isDark),
      generateBottomGrid(seed, boostedGasPrice),
      '</svg>'
    );
  }

  function gasPriceToStr(uint24 gasPrice) public pure returns (string memory) {
    uint24 gasPriceLeftSideZero = gasPrice / 1000;
    uint24 gasPriceRightSideZero = gasPrice % 1000;
    return string.concat(
      uint2str(gasPriceLeftSideZero),
      ".",
      leftPad(uint2str(gasPriceRightSideZero), 3)
    );
  }

  function generateGasPriceText(uint24 gasPrice, bool isDark) internal pure returns (string memory) {
    return string.concat(
      '<text x="50%" text-anchor="middle" style="white-space: pre; fill: #',
      isDark ? 'EEEEEE' : '111111',
      '; font-family: Arial, sans-serif; font-size: 33.3px;" y="353">Minted at ',
      gasPriceToStr(gasPrice),
      " gwei",
      "</text>"
    );
  }

  function generateTopGrid(uint256 seed, uint24 gasPrice) internal pure returns (string memory) {
    return string.concat(
      getCheckmarkRow(seed, gasPrice, 0, '104'),
      getCheckmarkRow(seed, gasPrice, 8, '144'),
      getCheckmarkRow(seed, gasPrice, 16, '184'),
      getCheckmarkRow(seed, gasPrice, 24, '224'),
      getCheckmarkRow(seed, gasPrice, 32, '264')
    );
  }

  function generateBottomGrid(uint256 seed, uint24 gasPrice) internal pure returns (string memory) {
    return string.concat(
      getCheckmarkRow(seed, gasPrice, 40, '400'),
      getCheckmarkRow(seed, gasPrice, 48, '440'),
      getCheckmarkRow(seed, gasPrice, 56, '480'),
      getCheckmarkRow(seed, gasPrice, 64, '520'),
      getCheckmarkRow(seed, gasPrice, 72, '560')
    );
  }

  /**
   * @dev depending on seed, provide a boost to the gas price
   * 25% chance of a 1x multiplier
   * 25% chance of a 2x multiplier
   * 25% chance of a 3x multiplier
   * 15% chance of a 4x multiplier
   * 10% chance of a 5x multiplier 
   */
  function getGasPriceMultiplier(uint256 seed) internal pure returns (uint8) {
    uint8 multiplier = 1;
    uint8 random = uint8(seed % 100);
    if (random < 25) {
      multiplier = 1;
    } else if (random < 50) {
      multiplier = 2;
    } else if (random < 75) {
      multiplier = 3;
    } else if (random < 90) {
      multiplier = 4;
    } else {
      multiplier = 5;
    }
    return multiplier;
  }

  /**
   * @dev For a given gas price (in 1/1000 gwei) and an index, returns whether a checkmark should be generated.
   * The index is the position of the checkmark in the 8 x 10 grid, starting from the top left.
   * For each index, generate a random number between 0 and 1000000. If the gas price is lower than the random number, do not generate a checkmark.
   * For an easy random number, let's use the seed and bit shift it to the right by the index
   */
  function checkmarkGenerates(uint256 seed, uint24 gasPrice, uint8 index) internal pure returns (bool) {
    return gasPrice > (uint24(seed >> index) % MAX_MINT_GAS_PRICE);
  }

  function getNumberOfCheckMarks(uint256 seed, uint24 gasPrice) internal pure returns (uint8) {
    uint8 count = 0;
    for (uint8 i = 0; i < 80; i++) {
      if (checkmarkGenerates(seed, gasPrice, i)) {
        count++;
      }
    }
    return count;
  }

  /**
   * @dev generates a row of checkmarks. Checkmarks are generated with the following rules:
   * 1. For each element in the row, use checmarkGenerates to see if it exists
   * 2. If it exists, generate a checkmark with a random color
   * 3. Colors are generated by taking the seed and bit shifting it to the right by the index * 3
   */
  function getCheckmarkRow(uint256 seed, uint24 gasPrice, uint8 startIndex, string memory yPos) internal pure returns (string memory) {
    // SVG is 512 pixels wide and the checks have a margin of 16 pixels between each other and a 104 pixel margin on the left and right
    return string.concat(
      '<g transform="translate(0 ',
      yPos,
      ')">',
      checkmarkGenerates(seed, gasPrice, startIndex) ?  getCheckmark(uint2hex(uint24(seed >> (startIndex * 3))), '104') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 1) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 1) * 3))), '144') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 2) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 2) * 3))), '184') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 3) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 3) * 3))), '224') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 4) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 4) * 3))), '264') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 5) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 5) * 3))), '304') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 6) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 6) * 3))), '344') : '',
      checkmarkGenerates(seed, gasPrice, startIndex + 7) ?  getCheckmark(uint2hex(uint24(seed >> ((startIndex + 7) * 3))), '384') : '',
      '</g>'
    );
  }

  function getCheckmark(string memory colorStr, string memory xPos) internal pure returns (string memory) {
    return string.concat(
      '<g transform="translate(',
      xPos,
      ' 0)" fill="#',
      colorStr,
      '"><path d="M22.25 12c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.66-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.33 2.19c-1.4-.46-2.91-.2-3.92.81s-1.26 2.52-.8 3.91c-1.31.67-2.2 1.91-2.2 3.34s.89 2.67 2.2 3.34c-.46 1.39-.21 2.9.8 3.91s2.52 1.26 3.91.81c.67 1.31 1.91 2.19 3.34 2.19s2.68-.88 3.34-2.19c1.39.45 2.9.2 3.91-.81s1.27-2.52.81-3.91c1.31-.67 2.19-1.91 2.19-3.34zm-11.71 4.2L6.8 12.46l1.41-1.42 2.26 2.26 4.8-5.23 1.47 1.36-6.2 6.77z" fill="#',
      colorStr,
      '"/></g>'
    );
  }
}