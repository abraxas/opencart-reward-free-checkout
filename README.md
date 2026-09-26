<p align="center">
  <img src="header.png" alt="Abraxas Labs — opencart-reward-free-checkout" width="100%">
</p>

<p align="center">
  <a href="https://abraxaslabs.tech"><strong>abraxaslabs.tech</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/abraxas">github.com/abraxas</a>
  &nbsp;·&nbsp;
  <a href="https://x.com/abraxas_null">@abraxas_null</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/abraxas/opencart-reward-free-checkout">opencart-reward-free-checkout</a>
</p>

# opencart-reward-free-checkout

**OpenCart** `4.1.0.4` — OpenCart

Unpublished OpenCart source finding: reward.save does not unset payment_method (coupon does). Free Checkout selected while points zero the cart, then points cleared; confirm writes a full-price order; free_checkout.confirm does not recheck total. Distinct from coupon race CVE-2025-15116.

| | |
|---|---|
| ID | Unpublished OpenCart source finding #1 (no CVE yet) |
| CWE | [CWE-840, CWE-863](https://cwe.mitre.org/data/definitions/863.html) |
| CVSS | **High: 6.5** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:N` |
| Product | [OpenCart](https://github.com/opencart/opencart) |
| Affected | all versions **through 4.1.0.4** (inclusive) |
| Patched | vendor patch — see references |
| Auth | authenticated (see source map) |
| License | [GNU Affero GPL v3.0](LICENSE) |
| Lab | `127.0.0.1` only · vendor/client disclosure pack, not a scanner |

---

## Advisory (from the source map)

reward.php 90-94 no unset payment_method. coupon.php 67-68 unsets. free_checkout.php confirm 47-55 session code only. confirm.php 279-283 editOrder while status 0.

---

## Entry

- **Method:** `POST`
- **Path:** `/index.php?route=extension/opencart/checkout/reward.save`
- **Router:** reward.save unsets session.reward only. coupon.save also unsets payment_method. free_checkout.confirm checks session payment code, not order total.
- **Notes:** Authenticated unpublished OpenCart #1 CWE-840 4.1.0.4. Customer with points. Distinct from coupon race CVE-2025-15116. Not a reverse shell. Disclose forum PM, not a public GitHub issue.

### Call chain

- `POST account/login.login`
- `POST checkout/cart.add product_id=36`
- `POST extension/opencart/checkout/reward.save reward=100`
- `GET checkout/payment_method.getMethods (free_checkout listed)`
- `POST checkout/payment_method.save free_checkout.free_checkout`
- `GET checkout/confirm.confirm (addOrder total~0 status 0)`
- `POST extension/opencart/checkout/reward.save reward=0`
- `GET checkout/confirm.confirm (editOrder full total)`
- `POST extension/opencart/payment/free_checkout.confirm`

### Lab preconditions

- OpenCart 4.1.0.4
- total_reward_status=1 and payment_free_checkout_status=1 (defaults)
- Logged-in customer with oc_customer_reward &gt;= product.points
- Product with oc_product.points &gt; 0 (demo 36 iPod Nano)

### Witness

oc_order.total at catalog price, payment_method free_checkout, order_status_id != 0, no negative oc_customer_reward for that order_id

### Not success

- eval/base64/system payload
- reverse shell
- coupon.save path (CVE-2025-15116 leftover hardening)
- order stays total 0 (honest free checkout)

---

## Patch / remediation

**Do this first:** Apply the vendor patch for **OpenCart**. See references.

**Verify after upgrade**

- Re-run `opencart-reward-free-checkout-Abraxas-Labs.py` against the patched build: the mapped witness must **not** appear.
- Confirm the vendor advisory / changeset in the deployed tree (see references).
- A WAF signature is delay, not a patch.

**If you cannot update immediately**

- Disable or isolate the affected component.
- Hunt for the witness condition on production (new privileged users, unexpected files, injected rows — whatever this CVE's map names).

---

## Reproduction (authorized lab)

Target **only** `http://127.0.0.1:18108` (or the loopback you bound). Do not point this script at the internet.

```bash
python3 opencart-reward-free-checkout-Abraxas-Labs.py
```

Success is the **witness** above in the response body. Generic 200 HTML is not it.

---

## Lab images

Loopback stack used to reproduce. Official images unless a `Dockerfile` in this folder builds from source.

- [`lab/docker-compose.yml`](lab/docker-compose.yml)
- [`lab/Dockerfile`](lab/Dockerfile)
- [`lab/run.sh`](lab/run.sh)
- [`lab/setup-opencart.sh`](lab/setup-opencart.sh)

Place OpenCart **4.1.0.4** `upload/` at `lab/www` (do not commit that tree):

https://github.com/opencart/opencart

Tag `4.1.0.4`. Then:

```bash
cd lab
docker compose up --force-recreate
./run.sh
```

Publish nothing except `127.0.0.1`.

---

## References

- [github.com/opencart/opencart](https://github.com/opencart/opencart) tag 4.1.0.4
- Contrast (already disclosed coupon race): [CVE-2025-15116](https://nvd.nist.gov/vuln/detail/CVE-2025-15116) — `coupon.save` unsets `payment_method`; `reward.save` does not
- Vendor intake: OpenCart forum PM to a moderator ([README](https://github.com/opencart/opencart/blob/master/README.md): do **not** post security flaws in a public location). No public GitHub issue on opencart/opencart.

- Abraxas Labs: [abraxaslabs.tech](https://abraxaslabs.tech) · [github.com/abraxas](https://github.com/abraxas) · [@abraxas_null](https://x.com/abraxas_null)

---

## Records (structured)

```
# OpenCart unpublished #1 — reward + Free Checkout underpay

CWE: CWE-840, CWE-863
Severity: High (HTTP lab SUCCESS, 95%)

## Description

`reward.save` does not unset `payment_method` (coupon does). Apply points to list Free Checkout, then clear points; confirm writes a full-price order; `free_checkout.confirm` does not recheck total.

## Product

OpenCart 4.1.0.4. Lab oracle: order 4 `total=100.00`, `order_status_id=1`, Free Checkout, customer points still 1000. Distinct from coupon race CVE-2025-15116.
```

---

## License

This disclosure pack is licensed under the **GNU Affero General Public License v3.0**. See [LICENSE](LICENSE).

---

## Disclaimer

This pack is for **the vendor, the site owner, and licensed labs**. The script talks to `127.0.0.1`. Using it against systems you do not own is not authorized by Abraxas Labs. No warranty.

<p align="center">
  <a href="https://abraxaslabs.tech">abraxaslabs.tech</a> ·
  <a href="https://github.com/abraxas">github.com/abraxas</a> ·
  <a href="https://x.com/abraxas_null">@abraxas_null</a>
</p>
