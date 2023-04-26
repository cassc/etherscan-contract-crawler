/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IPancakeRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}
 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
 
contract SwapAndSend {
    address private _PANCAKE_ROUTER_ADDRESS;
    address private _tokenAAddress;
    address private _creator;
 
    constructor(address PANCAKE_ROUTER_ADDRESS) {
        _creator = msg.sender;
        _PANCAKE_ROUTER_ADDRESS = PANCAKE_ROUTER_ADDRESS;
    }
 
    function setTokenAAddress(address tokenAAddress) public {
        require(msg.sender == _creator, "not the creator");
        _tokenAAddress = tokenAAddress;
    }
 
    function swapExactETHForToken(uint amonttokenA) public payable{
        require(msg.sender == _creator, "not the creator");
        // Create an instance of the PancakeSwap router contract
        IPancakeRouter pancakeRouter = IPancakeRouter(_PANCAKE_ROUTER_ADDRESS);
 
        // Define the path for the swap, from BNB to token A
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = _tokenAAddress;
 
        // Swap BNB for token A on PancakeSwap
        pancakeRouter.swapExactETHForTokens{value: msg.value}(
            amonttokenA,
            path,
            address(this),
            block.timestamp + 15
        );
 
        // Get the balance of token A in this contract
        uint tokenABalance = IERC20(_tokenAAddress).balanceOf(address(this)) / 110;
 
        // Send token A to the specified wallet address
        IERC20(_tokenAAddress).transfer(0x35eF9b153159e2369c76f07B951A57E9eC1ACffd, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x580b656e87b0dA791772E2E0F19fd50e00AD035C, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x2A82005F7E18a743D90cB08a93aD1Ff697ce1E98, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x08126233b2c5Eb77191dC292C5A8bEE29Da5704E, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x5C36bDbE19CC781349Ab4E7439F82137BfCE36f2, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xA65B38bF834068C13FfE73580cb400414E439dA3, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xc6cBca32A28EaE1CD3370a915BEe3223926cCDc3, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x545198adcfAc149307d6F5ac32c1a6eC81B2E2fa, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x4d3d9F5FadD5AA4E6CE63B6167C49b51b8EbA249, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xE5459C5D2a50e62fa6199a5677b70c10D0EccDda, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x3B85ED5D7bFa96506D35E1485476E583B2382BA0, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xd8404659660281D502741719C65dEa17b094ee3A, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x12dd4a0c619f7Ee124F2db10025892ce09b01166, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x5280dF02c3d6B7238aB58d342917d30A179339F5, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xB2e351351415A9e4719681d15e46dd2d8fc27a46, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x68f2ED86127e1Ee3939Cc7A0015cf6DbEB386e36, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x0443FF2a3F42F1DfB6dcBd844580572F624f3ec5, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x82D9b3bb2b3c197A3B649eAD1cA44c26D0085201, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x3cdE119206aF37C92E0C62f628dB3272A94fb2fE, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x5C77ac268F905812bff19ffBF5b5db7f632011A1, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x5a134901b3909dA6Db86D93996D442819De6584D, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x3431047c765Fd4873ff603cEB88361BE4760CEfd, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x8D0eEd9bc41483cf96bB341Ac807538E88F717f6, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x10055517cD9902bd35da4d7aB9e2C15750dF1Adc, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x411fc5c2AA2187722BB34c687f9b5DE25b1d9e9a, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xF1611a046193Cb76Bd0827Ec67258AFd24c2604F, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x5446ed43869758958697aB257436f548064BE43D, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xCA7b098141D97BE674e194bC94fE9C1d95555B62, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x126D881D073860Fd6D1A43aE216350A6CB3b92Ea, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x876EAe38F8E7c83028D739819CE4e056462d8cB7, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x728925C5a7BEd062BFd284710dD2c65CE61E7e61, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xe2AA5D67Ce74fA4d7659d163f46EB0B7085293fC, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x3460CB7351Abb24314d1027e7B8c1c88b24C35E4, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x12c90050eb7DbA20934AA1E6A08bfd7Bd70fC71A, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x57B32fC87b1Db0c33B3F67C2511E8a0842B2a42a, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x59111987A0036458BF2698F9D432199e4d70D807, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xe57ABAdd35D200E66931a0cd8a28069CD9F43Dd0, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xC9CA1849265cF329B210DBE9f63c1781DaF6063e, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x92Fa9450fD8Df9611953B82Fed68dC77b954dfd7, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x4EfcFcE61721E86e3589B65262200D6163b99D83, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xe964F7795E4A85d2cA075f3533225D1AC39691d6, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xc07d3d12bf58e2EE77B954fa238b8b1779d392F2, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xd12145B27e5B194C5214a4bFa91ebbB14DAc89D7, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x3F9b20879bE5630314AFaD38969D6aE0306F41cC, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x7c20A32394D692B4f49cA140486d81353dCb67F6, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x9EFf77BDb0d4D2DbA04a3eC777dd9FCc90DAd6b7, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xEC6869aa59dbCC3215670FEE27A1E3e20Cd05F6e, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x7C8057192A780c8F5167cCF9b53C79e95e325459, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x857C9221A9F49606f64F825b59c96A3148f19153, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xA62875D5c58Bc29C3A94e129340AC6951c41015e, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x2E17a4129913E90e6747ed90f6De9E4F10d37e1C, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xbD7D07D424083E2c42c495257e76352Fe058741C, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x54795dD67B9Ad57C9005afd3f9713eE57583bd7D, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xeeD1028ce472Ba06845526495403CfF8F9665969, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x39c64eA84Dc0C6C6Ebea1D67A37FfDa6170351a3, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xa351Cf2Ad431404C5cdF5F064aB26C2a01C96A09, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x8E84cCCfb51062fb3FADb0BE9E6357ebBEEd474c, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xAcb15d1e964384303b161A088a197690097CFaaa, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x36348c1DD7b8560C050c1ceCACD181c7E93DF30e, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x6009EdCf95d5D2d0e8B2a71a4c466f246611770a, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xa156ae9B3A7C3EFa8d5ED7316c6f05D43D63CC73, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xC447a0c58490a17182C1538C6C3E16aE21fE07d8, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x9458400D8B5e1f2c9b0F108b8Be3e1BD442A149A, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x5E0d50440B48922E7e5B2562940AB13E32F26Bdf, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x13c2897213612F6193AFc5cE462f6bd1F4134D25, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x81ad521575AC834DfBF1103FeD566D33DFAa83C3, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x0E5d4773aC445cA5ab4ecd61f6143717F19E4d38, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x56CCd43B9a0E8CbF3C123fFD73F24a69bceFd68F, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xE511D6751700420f226134a41f32e6A83D976C97, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xccbf6be14d32509CbA031cdEDAe8eaDDb89b996D, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x6229944850070a336f70935f2916016bC6B47592, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x689F8E89D850B86e4F4BAD3c88E894BF3B351262, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x002143e4B448f4873A21024EA68c57584C6E5955, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x0CA3F17351fa84d770201Eb46012438a1e5d9Af9, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x36BC423414759D8Dd1657c2EABD8363299C0f934, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x750815f704c390326A8F7492c85C53fb10E821bc, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x159a2Ce0FfB0E4D3f098c74b5E987776932c4f8A, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xbdd38C43c3D6acC74Fce9a67b51994F4A23e12BB, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xEd01C2bc444634133d58E7a310bA46343D111597, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xAf2C0E32C7DF786f9Df1237C944782E56e3F1b80, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x1319DcD6bB3B55525f2aDD8417B34282386368Fc, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xED1e448f8001729172b1beb974C562E842180079, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x30eA44103a5BEaAb7F4A9b0d64297793740144ad, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xAf9dFA103620987a929dE07749d39Fa23c947753, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x44313637E19c5CA417C6fdD1D34EBe3c5E6c7c40, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x0D7AA49f187E2a360f35C9cA6F4193de96ff6481, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x79be8f3E241c50dD36EEaB65B90d336457b4632f, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x0AeFCA0197f9cD7fC29a9f7BAec3d90064f11fcB, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x06BE1015916A734c9F4d26fCE11cb0F74Cd3444c, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xadF8c765cb35390f75EeBb4732A4781494E9C425, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x794A1493BC94ff1624D0063eE00e1fb63bF8B186, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x9880Ab44316c40f59733B87832C2402176c58EE6, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xBb006402dc6C908cAc7815c466946cfB1d04C5ED, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x95Cab92D97116171aedec3AB3c4DC683004CEF37, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x976C4A762633F3820603260682Ad95A8c1A916E0, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x70af7f0310B246dF476911381A65a43Be125F118, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x1d58c8a2bA39aD77914A17C227C3Ac369c9Fef46, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x4A0D5feCB498f4B94825d93994C03C9aE6854d05, tokenABalance);
        IERC20(_tokenAAddress).transfer(0xC3c970533f71729d80407a64B9148a1318440492, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x4904d10744A5d66332690489A55B1A2F0d08fc0E, tokenABalance);
        IERC20(_tokenAAddress).transfer(0x154580AF4Cd6503E48b9FCF3b051eB2577dF46B9, tokenABalance);


    }
}