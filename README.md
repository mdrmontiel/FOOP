# FOOP Tracker

Production, harvest and sales tracker for the FOOP greenhouses in Tormabum, Sierra Leone.

One shared app for the whole team: the field staff log plants and harvest, the sales
colleague logs market sales, and managers see everything — all on the same data,
from any phone.

---

## What's in this repo

| File | What it is |
|---|---|
| `index.html` | The whole app (one file). |
| `supabase_setup.sql` | Run once to build the database. |
| `manifest.json`, `icon.svg` | Lets the app install on a phone home screen. |
| `netlify.toml` | Netlify settings. |

---

## Roles

| Role | Can see | Cannot see |
|---|---|---|
| **Field** | Dashboard, Data, Estimations, Harvest | Anything about sales or money |
| **Sales** | Dashboard, Sales (record sales, market prices) | Plant/harvest data entry |
| **Manager** | Everything, including the Scenarios market comparison | — |

Each role signs in with its own PIN. Permissions are enforced by the database
(Row Level Security), not just hidden in the screen — the Field role genuinely
cannot read the sales table.

---

## Setup (do this once)

### 1. Create the database

1. Go to [supabase.com](https://supabase.com) and open your project.
2. Open **SQL Editor → New query**.
3. Paste the whole contents of `supabase_setup.sql` and press **Run**.

### 2. Create the three users

In Supabase go to **Authentication → Users → Add user**. Turn **Auto Confirm** ON.
Create these three, choosing your own PINs (**minimum 6 characters**):

| Email | Password = the PIN for |
|---|---|
| `field@foop.app` | Field team |
| `sales@foop.app` | Sales |
| `manager@foop.app` | Karen & Calvin |

Then copy each user's **UID** (shown in the users list) and run this in the SQL Editor:

```sql
insert into public.profiles (id, role, name) values
  ('PASTE-FIELD-UID',   'field',   'Field team'),
  ('PASTE-SALES-UID',   'sales',   'Sales'),
  ('PASTE-MANAGER-UID', 'manager', 'Karen & Calvin');
```

### 3. Connect the app to the database

In Supabase, open **Project Settings → API** and copy the **Project URL** and the
**anon public** key.

Open `index.html` and edit the two lines near the top of the script:

```js
const SUPABASE_URL      = "https://YOUR-PROJECT.supabase.co";
const SUPABASE_ANON_KEY = "PASTE-YOUR-ANON-PUBLIC-KEY-HERE";
```

Save and upload the file again.

> The anon key is safe to publish — it only grants what the security rules allow.
> **Never** put the `service_role` key in this file.

### 4. Publish

**Netlify:** drag the repo folder onto your existing site, or connect the GitHub repo
(no build command needed — it's a static file).

**GitHub Pages:** Settings → Pages → Source: `main`, folder `/root`.

### 5. Put it on the phones

Open the site in Chrome (Android) or Safari (iPhone) → **Share → Add to Home Screen**.
It then behaves like an app.

---

## Daily use

**Field team**
- *Data → Plant batches*: add a batch when something new is planted.
- Tap a batch when plants die and enter how many. Losses are counted automatically
  for that week — no separate tally to keep.
- *Data → This week's record*: enter kg harvested per crop, plus nursed and
  transplanted counts, then **Save week**.

**Sales**
- *Sales → Record a sale*: date, market, crop, kg delivered, kg sold, price.
  Transport, net revenue and spoilage are calculated automatically.
- Add the **voucher / tracking number** so each delivery can be traced.
- *Market prices*: update when the market survey changes.

**Managers**
- *Dashboard*: the numbers for donor and CEO reporting.
- *Harvest*: projection vs actual, overall and per crop.
- *Sales → Scenarios*: which market pays best for each crop after transport.

---

## Working without internet

The app keeps a copy of the data on the phone. If the signal drops:

- everything is still readable;
- new entries are saved on the phone and a bar shows how many are waiting;
- when the signal comes back they upload automatically.

Keep the app open until the offline bar disappears.

---

## Things to know

- **The free Supabase plan pauses a project after ~7 days without activity.**
  If nobody uses the app for a week, open the Supabase dashboard and press
  **Restore project**. There is a 90-day limit before a paused project is removed,
  so don't leave it asleep for months.
- **The free plan has no automatic backups.** Export a copy from time to time
  (Supabase → Table Editor → export as CSV).
- **To change a PIN:** Supabase → Authentication → Users → the user → reset password.
  Nothing needs to change in the code.
- **To change the dashboard targets** (plants in production / nursery):
  ```sql
  update public.settings
     set value = '{"prod":400,"nursery":200}'::jsonb
   where key = 'targets';
  ```

---

## Yield assumptions

Estimates use conservative kg-per-plant figures for Sierra Leone field conditions,
not greenhouse-ideal numbers — it is better to under-promise to donors and beat the
estimate. They can be edited in the app (*Estimations* tab) and the change is shared
with the whole team.
