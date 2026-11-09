# Compatibility fixtures

These scripts encode the UUIDs in `test/fixtures/compat/uuids.txt` with every
alphabet in `test/fixtures/compat/alphabets.tsv`, using other ShortUUID
implementations:

- `python_gen.py` - [shortuuid](https://pypi.org/project/shortuuid/) (Python), pinned in `requirements.txt`
- `js_gen.mjs` - [short-uuid](https://www.npmjs.com/package/short-uuid) (JavaScript), pinned in `package.json` / `package-lock.json`

The results are committed as `test/fixtures/compat/python.tsv` and `js.tsv`, and
`test/shortuuid/compat_test.exs` checks that this library produces the same short
IDs and decodes theirs back to the same UUIDs. `mix test` does not need Python or
Node.js.

To regenerate the fixtures:

```sh
python3 -m venv /tmp/compat-venv
/tmp/compat-venv/bin/pip install -r scripts/compat/requirements.txt
/tmp/compat-venv/bin/python scripts/compat/python_gen.py

(cd scripts/compat && npm ci && node js_gen.mjs)
```

The `compat` CI job does this weekly and whenever these files change (for example
on Dependabot updates), and fails if the fixtures differ from the committed ones.
